"""Generate self-signed SSL/TLS certificates for local HTTPS development.

Usage:
    python generate_ssl_cert.py
"""

from datetime import datetime, timedelta, timezone
from ipaddress import IPv4Address
from pathlib import Path

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.x509.oid import NameOID


def generate_self_signed_cert(output_dir: Path | None = None) -> tuple[Path, Path]:
    """Generates a self-signed RSA-2048 certificate for localhost."""
    out = output_dir or (Path(__file__).parent / "certs")
    out.mkdir(parents=True, exist_ok=True)

    key_path = out / "localhost.key"
    cert_path = out / "localhost.crt"

    if key_path.exists() and cert_path.exists():
        print(f"[HTTPS] Existing certificates found in {out}")
        return cert_path, key_path

    print("[HTTPS] Generating 2048-bit RSA private key...")
    private_key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048,
    )

    subject = issuer = x509.Name([
        x509.NameAttribute(NameOID.COUNTRY_NAME, "US"),
        x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, "California"),
        x509.NameAttribute(NameOID.ORGANIZATION_NAME, "MedTrace AI Security"),
        x509.NameAttribute(NameOID.COMMON_NAME, "localhost"),
    ])

    print("[HTTPS] Building TLS 1.3 / HTTPS x509 Certificate...")
    cert = (
        x509.CertificateBuilder()
        .subject_name(subject)
        .issuer_name(issuer)
        .public_key(private_key.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(datetime.now(timezone.utc))
        .not_valid_after(datetime.now(timezone.utc) + timedelta(days=365))
        .add_extension(
            x509.SubjectAlternativeName([
                x509.DNSName("localhost"),
                x509.IPAddress(IPv4Address("127.0.0.1")),
            ]),
            critical=False,
        )
        .add_extension(
            x509.BasicConstraints(ca=True, path_length=0),
            critical=True,
        )
        .sign(private_key, hashes.SHA256())
    )

    # Write private key
    key_path.write_bytes(
        private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.TraditionalOpenSSL,
            encryption_algorithm=serialization.NoEncryption(),
        )
    )

    # Write certificate
    cert_path.write_bytes(cert.public_bytes(serialization.Encoding.PEM))

    print(f"[HTTPS] Certificate created: {cert_path}")
    print(f"[HTTPS] Private key created: {key_path}")
    return cert_path, key_path


if __name__ == "__main__":
    generate_self_signed_cert()
