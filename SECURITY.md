# Security & Cryptographic Architecture — MedTrace AI

This document outlines the security architecture, encryption standards, key management protocols, and data lifecycle safeguards implemented across MedTrace AI.

---

## 1. Cryptographic Standard: AES-256-GCM

MedTrace AI enforces **AES-256-GCM** (Galois/Counter Mode), an Authenticated Encryption with Associated Data (AEAD) cipher standard recognized by NIST and HIPAA technical safeguards:

- **Algorithm**: AES (Advanced Encryption Standard) with a 256-bit symmetric key.
- **Mode**: Galois/Counter Mode (GCM) providing simultaneous confidentiality and cryptographic integrity verification.
- **Nonce/IV Specification**:
  - Exactly **12 bytes (96 bits)** generated via a cryptographically secure pseudorandom number generator (`os.urandom(12)`).
  - A strictly fresh, unique nonce is sampled for **every single encryption operation**.
  - **Nonce reuse is prohibited**: Reusing a nonce with the same key in GCM is cryptographically catastrophic; MedTrace AI enforces strict per-call generation.
- **Authentication Tag**:
  - **16 bytes (128 bits)** authentication tag computed by GCM.
  - Decryption strictly validates the authentication tag before returning any plaintext.
  - If a file or database field has been modified or corrupted by even a single bit, decryption is aborted and an integrity exception (`DecryptionError`) is raised.

---

## 2. Where Encryption & Decryption Occur

### A. Document Files at Rest

| Event | Location | Action |
|---|---|---|
| **File Upload** | `app.utils.file_utils.save_upload` | Plaintext bytes from the multipart upload stream are encrypted via `encryption_service.encrypt_bytes` and written to disk as `{uuid}.enc`. The unencrypted file is never permanently written to disk. |
| **OCR & PyMuPDF Extraction** | `app.services.document_service.extract_text` | Decryption occurs **ephemerally** using `ephemeral_decrypted_file`. Decrypted bytes are held in an isolated temporary file, read by the extractor, and immediately shredded/unlinked in a strict `finally` block. |
| **Document Viewing / Download** | `app.api.routes.documents.get_document_content` | Authorized users request `GET /api/documents/{id}/content`. The encrypted file is read from disk, decrypted **in-memory** in RAM, and streamed directly via HTTP response. No disk file is created. |
| **Document Deletion** | `app.utils.file_utils.delete_stored_file` | The encrypted `.enc` file is unlinked and removed from disk. |

### B. Database Fields at Rest (PHI / PII)

| Model Column | Data Type | Protection Mechanism |
|---|---|---|
| `Document.raw_text` | `EncryptedText` | Encrypted via AES-256-GCM and stored as `aes256gcm:<base64-payload>`. Transparently decrypted on ORM retrieval. |
| `Document.structured_entities` | `EncryptedText` | Encrypted via AES-256-GCM. Stores normalized clinical entities and extracted conditions/medications. |
| Legacy records | Text | Transparent backward compatibility: strings without the `aes256gcm:` prefix are passed through without error. |

---

## 3. Key Management

1. **Storage**:
   - The master 256-bit encryption key is loaded from the `MEDTRACE_ENCRYPTION_KEY` environment variable in `backend/.env`.
   - In cloud/production deployments, the key must be provisioned via an external Key Management Service (KMS) such as AWS Secrets Manager, Google Secret Manager, Azure Key Vault, or HashiCorp Vault.
2. **Isolation**:
   - The encryption key is stored separately from the encrypted medical files.
   - The key is **never** committed to version control (`.env` is excluded in `.gitignore`).
   - The key is **never** sent to the Flutter client or web browser.
   - The key is **never** returned in API responses, error logs, or database rows.
3. **Emergency Rotation**:
   - If a key needs to be rotated, an offline migration utility decrypts records with the current key and re-encrypts them with the successor key.

---

## 4. Ephemeral Decryption Lifecycle

During document processing (OCR fallback, PyMuPDF, python-docx), native libraries require a filesystem target:

```
[Encrypted .enc File on Disk]
           │
           ▼
[encryption_service.ephemeral_decrypted_file]
           │
           ├─► Decrypt in RAM
           ├─► Write to OS secure temp directory (tempfile.NamedTemporaryFile)
           ├─► Yield path to extractor
           │
     [Extraction Completes / Fails]
           │
           ▼
  [finally block]
           ├─► Overwrite file with zeros (zero-shredding)
           └─► Unlink/Delete temporary file from OS disk
```

Even if an uncaught exception occurs during extraction, the `finally` block guarantees that the temporary plaintext file is immediately destroyed.

---

## 5. Transport Security (TLS 1.3 / HTTPS)

MedTrace AI enforces end-to-end transport security for medical file transfer and API communication:

- **Local TLS 1.3 Certificates**:
  - `backend/generate_ssl_cert.py` provisions a 2048-bit RSA localhost certificate and key at `backend/certs/localhost.crt` and `backend/certs/localhost.key`.
  - Configured with Subject Alternative Names (SAN) for `localhost` and `127.0.0.1`.
- **1-Click HTTPS Backend Launcher**:
  - `run_backend_https.bat` automatically verifies certificates and starts Uvicorn with `--ssl-keyfile certs/localhost.key --ssl-certfile certs/localhost.crt`.
- **Cryptographic Transport Headers (`backend/app/main.py`)**:
  - `Strict-Transport-Security: max-age=63072000; includeSubDomains; preload` (enforcing browser HTTPS preloading).
  - `Content-Security-Policy: upgrade-insecure-requests; default-src 'self' https: data: blob: 'unsafe-inline' 'unsafe-eval'`.
  - `X-Security-Cipher: AES-256-GCM + TLS-1.3`.
  - `X-Transfer-Protocol: HTTPS` (dynamically verifies and signals encryption state).
  - `Cache-Control: no-store, no-cache, must-revalidate, private` for all `/api/documents` endpoints.
- **Client-Side Transport Security (`frontend/lib/services/api_service.dart`)**:
  - Automatically identifies TLS state via `isHttps` getter and `transportSecurityLabel`.
  - Injects `X-Transport-Security: TLS-1.3-Active` and `X-Requested-With: MedTraceAI-SecureClient` into file upload streams.
  - Multi-part file streaming verifies byte checksums and guards against in-flight payload corruption.

---

## 6. Access Control & IDOR Prevention

- **Document Scoping**: Source document retrieval (`GET /api/documents/{id}/content`) verifies authorization and document existence.
- **Safe Error Reporting**: If a document does not exist or access is forbidden, standard HTTP 404 or 403 status codes are returned.
- **Zero Information Leakage**: Decryption failures return a sanitized error message (`Failed to authenticate and decrypt stored medical document`) rather than exposing raw cryptographic errors or stack traces.

---

## 7. Security Limitations & Disclaimer

No software system is "unhackable" or "100% secure". The security controls in MedTrace AI are designed to mitigate risks in accordance with defense-in-depth principles:
- An attacker who obtains physical access to encrypted `.enc` files without the encryption key cannot read patient data.
- An attacker who modifies an encrypted file cannot cause the application to accept forged clinical records due to GCM authentication tags.
- Host machine compromise (e.g., root access to the runtime environment with access to memory and environment variables) could expose keys in memory. Production deployments must harden OS hosts, apply kernel patches, and enforce least-privilege access controls.
