import os
import sys
import time
import subprocess
import requests

def main():
    print("[*] Launching MedTrace AI FastAPI backend server...")
    server = subprocess.Popen(
        [sys.executable, "-m", "uvicorn", "app.main:app", "--host", "127.0.0.1", "--port", "8000"],
        cwd=os.path.dirname(os.path.abspath(__file__)),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )

    base_url = "http://127.0.0.1:8000"
    print("[*] Waiting for server to become ready...")
    ready = False
    for _ in range(10):
        time.sleep(0.5)
        if server.poll() is not None:
            stdout, stderr = server.communicate()
            raise RuntimeError(f"Server exited early: stdout={stdout}, stderr={stderr}")
        try:
            resp = requests.get(f"{base_url}/api/health", timeout=2)
            if resp.status_code == 200:
                ready = True
                break
        except Exception:
            pass

    assert ready, "Server did not become ready within 5 seconds"

    try:
        # 1. Health check
        print("[1] Checking /api/health and /api/health/detailed endpoints...")
        resp = requests.get(f"{base_url}/api/health/detailed", timeout=5)
        assert resp.status_code == 200, f"Health check failed: {resp.status_code}"
        health_data = resp.json()
        print(f"    Health: status={health_data.get('status')}, components={health_data.get('components')}")

        # 2. Generate and Upload sample clinical document
        print("[2] Generating and uploading clinical_record.pdf...")
        import pymupdf as fitz
        sample_doc = fitz.open()
        page = sample_doc.new_page()
        page.insert_text(
            (50, 72),
            "MEDTRACE CLINICAL REPORT\n\n"
            "PATIENT: John Doe (DOB: 1968-04-12)\n"
            "DIAGNOSES:\n"
            "1. Essential Hypertension (ICD-10 I10)\n"
            "2. Type 2 Diabetes Mellitus without complications (E11.9)\n"
            "3. Hyperlipidemia (E78.5)\n\n"
            "MEDICATIONS:\n"
            "- Metformin 500mg PO BID with meals\n"
            "- Lisinopril 10mg PO daily in morning\n"
            "- Atorvastatin 20mg PO QHS\n\n"
            "VITALS & LABS:\n"
            "- BP: 142/88 mmHg\n"
            "- Pulse: 74 bpm\n"
            "- SpO2: 98%\n"
            "- Blood Glucose: 142 mg/dL\n"
            "- HbA1c: 7.2%\n\n"
            "ASSESSMENT & PLAN:\n"
            "Hypertension marginally controlled, continue Lisinopril. Diabetes HbA1c stable. "
            "Patient advised on sodium restriction and follow-up in 3 months.\n",
            fontsize=11,
        )
        sample_pdf_bytes = sample_doc.write()
        sample_doc.close()

        upload_resp = requests.post(
            f"{base_url}/api/documents/upload",
            files={"file": ("clinical_record.pdf", sample_pdf_bytes, "application/pdf")},
            timeout=10,
        )
        assert upload_resp.status_code == 201, f"Upload failed: {upload_resp.status_code} {upload_resp.text}"
        doc_id = upload_resp.json()["document_id"]
        print(f"    Uploaded doc_id: {doc_id}")

        # 3. Process extraction (Phase 2)
        print("[3] Processing document text extraction...")
        proc_resp = requests.post(f"{base_url}/api/documents/{doc_id}/process", timeout=10)
        assert proc_resp.status_code == 200, f"Process failed: {proc_resp.status_code}"
        print(f"    Extraction method: {proc_resp.json().get('extraction_method')}, chars: {proc_resp.json().get('char_count')}")

        # 4. Clinical AI Analysis (Phase 3)
        print("[4] Executing Phase 3 AI Clinical Classification & Entity Extraction...")
        analyze_resp = requests.post(f"{base_url}/api/documents/{doc_id}/analyze", timeout=15)
        assert analyze_resp.status_code == 200, f"Analyze failed: {analyze_resp.status_code} {analyze_resp.text}"
        analysis = analyze_resp.json()
        print(f"    Document Type: {analysis.get('document_type')}")
        print(f"    Quality Score: {analysis.get('quality_score')}/100")
        print(f"    AI Provider: {analysis.get('provider_used')}")
        entities = analysis.get("entities", {})
        print(f"    Diagnoses: {entities.get('diagnoses')}")
        print(f"    Medications: {[m.get('name') for m in entities.get('medications', [])]}")
        print(f"    Vitals: {entities.get('vitals')}")
        print(f"    Critical Flags: {entities.get('critical_flags')}")

        # 5. AI Copilot Chat Query Grounded on the Document
        print("[5] Testing Clinical Copilot grounded query...")
        copilot_resp = requests.post(
            f"{base_url}/api/documents/copilot",
            json={
                "query": "What medications and dosages are prescribed for this patient?",
                "document_id": doc_id,
            },
            timeout=10,
        )
        assert copilot_resp.status_code == 200, f"Copilot query failed: {copilot_resp.status_code} {copilot_resp.text}"
        copilot_data = copilot_resp.json()
        print(f"    Copilot Answer: {copilot_data.get('response')[:120]}...")
        print(f"    Grounding Sources: {copilot_data.get('source_documents')}")
        print(f"    Tags: {copilot_data.get('tags')}")

        # 6. Global Copilot Chat Query
        print("[6] Testing Global Clinical Copilot query across all documents...")
        global_copilot_resp = requests.post(
            f"{base_url}/api/documents/copilot",
            json={"query": "Summarize hypertension and cardiac risk factors"},
            timeout=10,
        )
        assert global_copilot_resp.status_code == 200, f"Global copilot failed: {global_copilot_resp.status_code}"
        print(f"    Global Answer: {global_copilot_resp.json().get('response')[:120]}...")

        # 7. Cleanup
        print("[7] Cleaning up test document...")
        del_resp = requests.delete(f"{base_url}/api/documents/{doc_id}", timeout=5)
        assert del_resp.status_code == 200, f"Delete failed: {del_resp.status_code}"
        print(f"    Deleted doc_id {doc_id}: {del_resp.json().get('deleted')}")

        print("\n[SUCCESS] ALL PHASE 3 BACKEND AND COPILOT ENDPOINTS PASSED PERFECTLY!")

    finally:
        server.terminate()
        server.wait()

if __name__ == "__main__":
    main()
