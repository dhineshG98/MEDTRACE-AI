import React, { useState } from 'react';
import { 
  HeartPulse, 
  Pill, 
  TestTube, 
  Stethoscope, 
  ShieldCheck, 
  AlertOctagon, 
  GitFork, 
  Activity, 
  FileText, 
  Lock, 
  Calendar, 
  Eye, 
  Sparkles, 
  CheckCircle2, 
  X,
  Layers
} from 'lucide-react';

interface SolutionsMegaMenuProps {
  isOpen: boolean;
  onClose: () => void;
  onSelectCategory?: (category: string) => void;
}

type SpecialtyCategory = 
  | 'internal_med' 
  | 'oncology' 
  | 'endocrinology' 
  | 'emergency' 
  | 'primary_care' 
  | 'pathology';

export const SolutionsMegaMenu: React.FC<SolutionsMegaMenuProps> = ({ isOpen, onClose, onSelectCategory }) => {
  const [activeCategory, setActiveCategory] = useState<SpecialtyCategory>('internal_med');

  if (!isOpen) return null;

  const categories = [
    { id: 'internal_med', label: 'Cardiology & Internal' },
    { id: 'oncology', label: 'Oncology & Hematology' },
    { id: 'endocrinology', label: 'Endocrinology & Diabetes' },
    { id: 'emergency', label: 'Emergency & Inpatient' },
    { id: 'primary_care', label: 'Primary Care & Outpatient' },
    { id: 'pathology', label: 'Pathology & Genomics' },
  ];

  const categoryDetails: Record<SpecialtyCategory, {
    group1Title: string;
    group1Items: Array<{ icon: React.ReactNode; title: string; desc: string }>;
    group2Title: string;
    group2Items: Array<{ icon: React.ReactNode; title: string; desc: string }>;
    group3Title: string;
    group3Items: Array<{ icon: React.ReactNode; title: string; desc: string }>;
  }> = {
    internal_med: {
      group1Title: 'Cardiovascular & Clinical Lifecycle',
      group1Items: [
        { icon: <HeartPulse size={20} />, title: 'CardioView', desc: 'Hypertension & Arrhythmia' },
        { icon: <Pill size={20} />, title: 'MedTrace Rx', desc: 'Anti-hypertensive & Statin Regimens' },
        { icon: <Activity size={20} />, title: 'Vitals360', desc: 'Blood Pressure & Heart Rate' },
        { icon: <Stethoscope size={20} />, title: 'Clinician Portal', desc: 'Attending Physician Notes' },
        { icon: <Calendar size={20} />, title: 'Timeline View', desc: 'Longitudinal Episode Log' },
        { icon: <TestTube size={20} />, title: 'Lipid Panel Pro', desc: 'Cholesterol, HDL/LDL & Triglycerides' },
        { icon: <FileText size={20} />, title: 'ECG Dictation', desc: 'Telemetry & Holter Parsing' },
        { icon: <Layers size={20} />, title: 'Summary Dashboards', desc: 'Actionable Clinical Index' },
      ],
      group2Title: 'Negation & Risk Shield',
      group2Items: [
        { icon: <AlertOctagon size={20} />, title: 'Denial Shield', desc: 'Denies Chest Pain Rule-out' },
        { icon: <ShieldCheck size={20} />, title: 'NKDA Filter', desc: 'No Known Drug Allergy Flag' },
        { icon: <CheckCircle2 size={20} />, title: 'Exclusion Tracing', desc: 'Ruled-Out MI Validation' },
        { icon: <Eye size={20} />, title: 'Source Inspector', desc: 'Highlight Context in Record' },
      ],
      group3Title: 'Knowledge Graph & Therapy Links',
      group3Items: [
        { icon: <GitFork size={20} />, title: 'Drug-Disease Linker', desc: 'Amlodipine → Treats → HTN' },
        { icon: <Lock size={20} />, title: 'AES-256 Vault', desc: 'HIPAA-aware Encrypted Triples' },
        { icon: <Sparkles size={20} />, title: 'FHIR Export Map', desc: 'Standardized Resource Model' },
        { icon: <FileText size={20} />, title: 'Discharge Summary', desc: 'Automated Regimen Synthesis' },
      ],
    },
    oncology: {
      group1Title: 'Oncology Data Lifecycle',
      group1Items: [
        { icon: <Activity size={20} />, title: 'OncoTrace', desc: 'Tumor Board & Staging Notes' },
        { icon: <Pill size={20} />, title: 'ChemoProtocol', desc: 'Infusion Dosing & Schedules' },
        { icon: <TestTube size={20} />, title: 'Biomarker View', desc: 'PD-L1, HER2, EGFR Biomarkers' },
        { icon: <FileText size={20} />, title: 'Histopathology', desc: 'Biopsy & Surgical Pathology' },
      ],
      group2Title: 'Negation & Toxicity Filter',
      group2Items: [
        { icon: <AlertOctagon size={20} />, title: 'Toxicity Guard', desc: 'Rule out Adverse Events' },
        { icon: <CheckCircle2 size={20} />, title: 'Remission Marker', desc: 'No Evidence of Recurrence' },
      ],
      group3Title: 'Semantic Oncology Graph',
      group3Items: [
        { icon: <GitFork size={20} />, title: 'Regimen Correlate', desc: 'Immunotherapy to Target Links' },
        { icon: <Lock size={20} />, title: 'PHI Vault Shield', desc: 'Encrypted Genomic Annotations' },
      ],
    },
    endocrinology: {
      group1Title: 'Metabolic & Glycemic Lifecycle',
      group1Items: [
        { icon: <TestTube size={20} />, title: 'GlycoView', desc: 'HbA1c & Fasting Glucose Panels' },
        { icon: <Pill size={20} />, title: 'Insulin Regimen', desc: 'Basal/Bolus Units & Titration' },
        { icon: <HeartPulse size={20} />, title: 'Thyroid Panel', desc: 'TSH, Free T3 & Free T4' },
        { icon: <FileText size={20} />, title: 'Comorbidity Index', desc: 'Retinopathy & Neuropathy' },
      ],
      group2Title: 'Negation & Quality Guard',
      group2Items: [
        { icon: <AlertOctagon size={20} />, title: 'Hypo Denial', desc: 'Denies Hypoglycemic Episodes' },
        { icon: <CheckCircle2 size={20} />, title: 'Target Filter', desc: 'Pre-diabetic vs Active Flag' },
      ],
      group3Title: 'Endocrine Relationships',
      group3Items: [
        { icon: <GitFork size={20} />, title: 'Metformin Link', desc: 'Metformin → Type 2 Diabetes' },
        { icon: <Sparkles size={20} />, title: 'Lifestyle Synthesis', desc: 'Diet & Exercise Mentions' },
      ],
    },
    emergency: {
      group1Title: 'Triage & Acute Inpatient',
      group1Items: [
        { icon: <Activity size={20} />, title: 'TriageTrace', desc: 'Chief Complaint & ESI Level' },
        { icon: <Pill size={20} />, title: 'Stat Medications', desc: 'IV Push & Acute Infusion' },
        { icon: <TestTube size={20} />, title: 'Critical Labs', desc: 'Troponin, Lactate, ABG' },
        { icon: <Calendar size={20} />, title: 'Admission Flow', desc: 'ED to ICU/Floor Transfer' },
      ],
      group2Title: 'Acute Exclusions & Negations',
      group2Items: [
        { icon: <AlertOctagon size={20} />, title: 'Acute Rule-Out', desc: 'Rules Out Sepsis/Stroke' },
        { icon: <ShieldCheck size={20} />, title: 'Contrast Allergy', desc: 'CT Contrast Hypersensitivity' },
      ],
      group3Title: 'Inpatient Graph Connections',
      group3Items: [
        { icon: <GitFork size={20} />, title: 'Discharge Plan', desc: 'Post-acute Follow-up Routing' },
        { icon: <Lock size={20} />, title: 'Audit Trail', desc: 'Encrypted Multi-Provider Handoff' },
      ],
    },
    primary_care: {
      group1Title: 'Ambulatory & Routine Care',
      group1Items: [
        { icon: <Stethoscope size={20} />, title: 'Annual Wellness', desc: 'Preventive Health Checks' },
        { icon: <Pill size={20} />, title: 'Med Reconciliation', desc: 'Active vs Historical Rx' },
        { icon: <TestTube size={20} />, title: 'CBC / CMP View', desc: 'Routine Blood Profiles' },
        { icon: <Calendar size={20} />, title: 'Immunization Log', desc: 'Vaccine History & Boosters' },
      ],
      group2Title: 'Allergy & History Screening',
      group2Items: [
        { icon: <AlertOctagon size={20} />, title: 'Family History', desc: 'Distinguishes Patient vs Family' },
        { icon: <CheckCircle2 size={20} />, title: 'Social History', desc: 'Smoking/Alcohol Non-user Flags' },
      ],
      group3Title: 'Longitudinal Health Records',
      group3Items: [
        { icon: <GitFork size={20} />, title: 'Provider Network', desc: 'Referral & Specialist Linkage' },
        { icon: <Sparkles size={20} />, title: 'Patient Summary', desc: 'Plain-language Digest' },
      ],
    },
    pathology: {
      group1Title: 'Diagnostic Lab & Pathology',
      group1Items: [
        { icon: <TestTube size={20} />, title: 'Microbiology', desc: 'Culture & Antibiotic Sensitivity' },
        { icon: <FileText size={20} />, title: 'Gross Pathology', desc: 'Specimen Description & Stains' },
        { icon: <Activity size={20} />, title: 'Cytology View', desc: 'Cellular Morphology Reports' },
        { icon: <Pill size={20} />, title: 'Antibiogram', desc: 'Resistant Strain Detection' },
      ],
      group2Title: 'Pathology Negative Findings',
      group2Items: [
        { icon: <CheckCircle2 size={20} />, title: 'Clear Margins', desc: 'No Malignancy in Margins' },
        { icon: <AlertOctagon size={20} />, title: 'Negative Stains', desc: 'Non-reactive Immuno-stains' },
      ],
      group3Title: 'Pathology Graph Mapping',
      group3Items: [
        { icon: <GitFork size={20} />, title: 'Organ-Lesion Triples', desc: 'Anatomical Site Mapping' },
        { icon: <Lock size={20} />, title: 'Encrypted Repository', desc: 'High-volume Lab Storage' },
      ],
    },
  };

  const activeData = categoryDetails[activeCategory];

  return (
    <div 
      style={{
        position: 'absolute',
        top: '100%',
        left: 0,
        right: 0,
        background: '#131a24',
        borderTop: '1px solid var(--border-subtle)',
        borderBottom: '2px solid var(--peloton-green)',
        boxShadow: '0 25px 60px rgba(0, 0, 0, 0.85)',
        zIndex: 100,
        animation: 'fadeIn 0.2s ease-out',
      }}
    >
      <div 
        style={{
          maxWidth: '1400px',
          margin: '0 auto',
          display: 'grid',
          gridTemplateColumns: '260px 1fr',
          minHeight: '480px',
        }}
      >
        {/* Left Vertical Rail */}
        <div 
          style={{
            background: 'rgba(14, 20, 30, 0.95)',
            borderRight: '1px solid var(--border-subtle)',
            padding: '24px 16px',
            display: 'flex',
            flexDirection: 'column',
            gap: '8px',
          }}
        >
          <div style={{ fontSize: '0.72rem', fontWeight: 800, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.08em', padding: '0 12px 12px' }}>
            Clinical Specialty
          </div>

          {categories.map((cat) => {
            const isActive = activeCategory === cat.id;
            return (
              <button
                key={cat.id}
                onClick={() => {
                  setActiveCategory(cat.id as SpecialtyCategory);
                  if (onSelectCategory) onSelectCategory(cat.label);
                }}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  padding: '12px 16px',
                  borderRadius: 'var(--radius-sm)',
                  border: 'none',
                  background: isActive ? 'var(--peloton-green)' : 'transparent',
                  color: isActive ? '#0a1508' : 'var(--text-primary)',
                  fontWeight: isActive ? 800 : 600,
                  fontSize: '0.9rem',
                  cursor: 'pointer',
                  textAlign: 'left',
                  transition: 'all 0.15s ease',
                  boxShadow: isActive ? '0 4px 14px var(--peloton-green-glow)' : 'none',
                }}
              >
                <span>{cat.label}</span>
                <span style={{ fontSize: '1.2rem', lineHeight: 1, opacity: isActive ? 1 : 0.4 }}>&rsaquo;</span>
              </button>
            );
          })}

          <div style={{ marginTop: 'auto', padding: '16px 12px 0', borderTop: '1px solid var(--border-subtle)' }}>
            <button 
              onClick={onClose}
              style={{
                background: 'transparent',
                border: 'none',
                color: 'var(--text-dim)',
                fontSize: '0.8rem',
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: '6px',
              }}
            >
              <X size={14} />
              <span>Close Menu</span>
            </button>
          </div>
        </div>

        {/* Right Content Matrix matching Peloton Screenshot */}
        <div 
          style={{
            padding: '36px 48px',
            background: '#131a24',
            overflowY: 'auto',
            maxHeight: '620px',
            display: 'flex',
            flexDirection: 'column',
            gap: '32px',
          }}
        >
          {/* Group 1 */}
          <div>
            <div 
              style={{
                fontSize: '0.95rem',
                fontWeight: 800,
                color: '#ffffff',
                textTransform: 'uppercase',
                letterSpacing: '0.04em',
                marginBottom: '18px',
                display: 'flex',
                alignItems: 'center',
                gap: '8px'
              }}
            >
              <span>{activeData.group1Title}</span>
            </div>

            <div 
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(4, 1fr)',
                gap: '20px 16px',
              }}
              className="mega-menu-grid"
            >
              {activeData.group1Items.map((item, idx) => (
                <div 
                  key={idx}
                  onClick={onClose}
                  style={{
                    display: 'flex',
                    alignItems: 'flex-start',
                    gap: '12px',
                    padding: '8px',
                    borderRadius: 'var(--radius-sm)',
                    cursor: 'pointer',
                    transition: 'background 0.15s ease',
                  }}
                  className="mega-menu-item"
                >
                  <div style={{ color: 'var(--peloton-accent)', marginTop: '2px', flexShrink: 0 }}>
                    {item.icon}
                  </div>
                  <div>
                    <div style={{ fontWeight: 700, color: '#ffffff', fontSize: '0.88rem', lineHeight: 1.2 }}>
                      {item.title}
                    </div>
                    <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: '3px', lineHeight: 1.3 }}>
                      {item.desc}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Group 2 */}
          <div style={{ borderTop: '1px solid var(--border-subtle)', paddingTop: '24px' }}>
            <div 
              style={{
                fontSize: '0.95rem',
                fontWeight: 800,
                color: '#ffffff',
                textTransform: 'uppercase',
                letterSpacing: '0.04em',
                marginBottom: '18px',
              }}
            >
              {activeData.group2Title}
            </div>

            <div 
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(4, 1fr)',
                gap: '20px 16px',
              }}
              className="mega-menu-grid"
            >
              {activeData.group2Items.map((item, idx) => (
                <div 
                  key={idx}
                  onClick={onClose}
                  style={{
                    display: 'flex',
                    alignItems: 'flex-start',
                    gap: '12px',
                    padding: '8px',
                    borderRadius: 'var(--radius-sm)',
                    cursor: 'pointer',
                  }}
                  className="mega-menu-item"
                >
                  <div style={{ color: '#60a5fa', marginTop: '2px', flexShrink: 0 }}>
                    {item.icon}
                  </div>
                  <div>
                    <div style={{ fontWeight: 700, color: '#ffffff', fontSize: '0.88rem', lineHeight: 1.2 }}>
                      {item.title}
                    </div>
                    <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: '3px', lineHeight: 1.3 }}>
                      {item.desc}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Group 3 */}
          <div style={{ borderTop: '1px solid var(--border-subtle)', paddingTop: '24px' }}>
            <div 
              style={{
                fontSize: '0.95rem',
                fontWeight: 800,
                color: '#ffffff',
                textTransform: 'uppercase',
                letterSpacing: '0.04em',
                marginBottom: '18px',
              }}
            >
              {activeData.group3Title}
            </div>

            <div 
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(4, 1fr)',
                gap: '20px 16px',
              }}
              className="mega-menu-grid"
            >
              {activeData.group3Items.map((item, idx) => (
                <div 
                  key={idx}
                  onClick={onClose}
                  style={{
                    display: 'flex',
                    alignItems: 'flex-start',
                    gap: '12px',
                    padding: '8px',
                    borderRadius: 'var(--radius-sm)',
                    cursor: 'pointer',
                  }}
                  className="mega-menu-item"
                >
                  <div style={{ color: '#cbd5e1', marginTop: '2px', flexShrink: 0 }}>
                    {item.icon}
                  </div>
                  <div>
                    <div style={{ fontWeight: 700, color: '#ffffff', fontSize: '0.88rem', lineHeight: 1.2 }}>
                      {item.title}
                    </div>
                    <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: '3px', lineHeight: 1.3 }}>
                      {item.desc}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
