import os
import json
import urllib.request
import urllib.error
from typing import Optional, Dict, Any

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

SYSTEM_PROMPT = """You are HealthShield AI, an educational healthcare assistant.
Your purpose is to explain medical terminology, health concepts, lab report values, wellness, nutrition, and exercise in clear, accessible language.

STRICT MANDATORY SAFETY RULES:
1. You are NOT a physician and CANNOT provide a medical diagnosis or disease confirmation.
2. NEVER prescribe medications, recommend dosages, or advise stopping or altering any prescribed treatments.
3. If a user asks for a diagnosis (e.g., "Do I have cancer?", "Diagnose me"), politely refuse and instruct them to consult a licensed medical doctor.
4. If a user describes emergency or life-threatening symptoms (such as severe chest pain, breathing difficulty, acute neurological deficits, uncontrolled bleeding, or loss of consciousness), urgently advise them to contact local emergency services or visit the nearest emergency department immediately.
5. Always maintain an objective, compassionate, and informative educational tone.
6. Conclude with a brief standard educational disclaimer:
*Disclaimer: HealthShield AI provides educational information only and does not offer medical diagnoses or prescriptions. Always consult a qualified healthcare provider.*
"""

def generate_health_assistant_response(query: str, patient_context: Optional[Dict[str, Any]] = None) -> str:
    """
    Unified AI Assistant response generator.
    Backend decides provider: calls Gemini API if GEMINI_API_KEY is configured;
    falls back cleanly to the local context-aware educational engine otherwise.
    """
    clean_query = query.strip()
    if not clean_query:
        return "Please ask a health education or medical terminology question."

    # Check for Gemini API key
    api_key = os.getenv("GEMINI_API_KEY") or GEMINI_API_KEY
    if api_key and api_key.strip():
        try:
            return _call_gemini_api(clean_query, api_key.strip(), patient_context)
        except Exception as e:
            # Fall through to local fallback gracefully
            print(f"[AI_DEBUG] Gemini API call failed ({e}). Falling back to local educational engine.")

    # Local fallback
    return _local_educational_fallback(clean_query, patient_context)

def _call_gemini_api(query: str, api_key: str, patient_context: Optional[Dict[str, Any]]) -> str:
    """Call Google Gemini 1.5 Flash REST API with prompt guardrails."""
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={api_key}"

    context_str = ""
    if patient_context:
        safe_ctx = []
        if patient_context.get("blood_group"):
            safe_ctx.append(f"Blood Group: {patient_context['blood_group']}")
        if patient_context.get("allergies"):
            safe_ctx.append(f"Known Allergies: {patient_context['allergies']}")
        if patient_context.get("conditions"):
            safe_ctx.append(f"Reported Conditions: {patient_context['conditions']}")
        if safe_ctx:
            context_str = f"\n[Patient Non-Sensitive Profile Context]: {'; '.join(safe_ctx)}\n"

    full_prompt = f"{SYSTEM_PROMPT}\n{context_str}\nUser Question: {query}\nResponse:"

    payload = {
        "contents": [
            {
                "parts": [
                    {"text": full_prompt}
                ]
            }
        ],
        "generationConfig": {
            "temperature": 0.4,
            "maxOutputTokens": 600
        }
    }

    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST"
    )

    with urllib.request.urlopen(req, timeout=10) as resp:
        res_data = json.loads(resp.read().decode("utf-8"))

    try:
        text = res_data["candidates"][0]["content"]["parts"][0]["text"]
        return text.strip()
    except (KeyError, IndexError):
        raise ValueError("Invalid response structure from Gemini API")

def _local_educational_fallback(query: str, patient_context: Optional[Dict[str, Any]]) -> str:
    """Context-aware local educational engine with strict safety guardrails."""
    q = query.lower()
    disclaimer = "\n\n*Disclaimer: HealthShield AI provides educational information only and does not offer medical diagnoses or prescriptions. Always consult a qualified healthcare provider.*"

    # 1. Unsafe Requests Guardrails
    if any(k in q for k in ["diagnose me", "what disease do i have", "tell me what disease", "do i have cancer", "diagnose this"]):
        return ("HealthShield AI cannot provide a medical diagnosis or identify specific illnesses. "
                "Diagnosing conditions requires a clinical examination, diagnostic lab work, and evaluation by a licensed healthcare professional. "
                "Please schedule an appointment with a doctor for personal medical assessment." + disclaimer)

    if any(k in q for k in ["what medicine should i take", "prescribe", "what drug should i take", "dosage", "should i stop my medication", "stop taking"]):
        return ("HealthShield AI cannot prescribe medications, recommend pharmaceutical dosages, or advise stopping prescribed drugs. "
                "Any changes to medical prescriptions should be made solely in consultation with your prescribing doctor." + disclaimer)

    # 2. Emergency Symptoms Guardrails
    if any(k in q for k in ["chest pain", "can't breathe", "difficulty breathing", "severe bleeding", "heart attack", "stroke", "unconscious"]):
        return ("**EMERGENCY WARNING**: The symptoms you described can indicate an acute, life-threatening medical emergency. "
                "Please call your local emergency services (e.g., 911 / 112 / 108) or proceed to the nearest hospital emergency room immediately." + disclaimer)

    # 3. Medical Concepts & Terminology
    if any(k in q for k in ["blood pressure", "hypertension", " bp"]):
        return ("Hypertension (high blood pressure) occurs when the pressure of blood flowing through your arteries is consistently elevated. "
                "Standard normal blood pressure is typically below 120/80 mmHg. Lifestyle measures like a balanced low-sodium diet, regular aerobic activity, and stress management help support healthy vascular function." + disclaimer)

    if any(k in q for k in ["fever", "temperature", "feverish"]):
        return ("A fever is a temporary elevation in body temperature, usually an immune response to fighting infection. "
                "Staying hydrated and resting are essential supportive measures. Seek immediate medical attention if a fever exceeds 103°F (39.4°C), lasts more than 3 days, or is accompanied by difficulty breathing or a stiff neck." + disclaimer)

    if any(k in q for k in ["bmi", "body mass index"]):
        return ("Body Mass Index (BMI) is a screening metric calculated as Weight (kg) divided by Height (m) squared. "
                "It categorizes weight status into Underweight (<18.5), Normal (18.5-24.9), Overweight (25-29.9), and Obese (≥30). "
                "BMI is a general screening indicator rather than a direct measurement of body composition." + disclaimer)

    if any(k in q for k in ["allergy", "allergies", "allergic"]):
        allergy_note = ""
        if patient_context and patient_context.get("allergies"):
            allergy_note = f"\n*Note: Your medical profile lists allergy: [{patient_context['allergies']}]. Always verify labels and inform clinicians.*"
        return ("Allergies are hypersensitive immune responses triggered by specific foreign substances such as foods, medications, or pollen. "
                "Managing allergies involves identifying triggers and, where appropriate, carrying prescribed medications like epinephrine." + allergy_note + disclaimer)

    if any(k in q for k in ["diabetes", "sugar", "glucose"]):
        return ("Blood glucose refers to the concentration of sugar in your bloodstream. Chronic elevation is characteristic of Diabetes Mellitus. "
                "Regular physical activity, fiber-rich diets, and routine fasting blood glucose screenings help monitor metabolic health." + disclaimer)

    if any(k in q for k in ["report", "lab value", "test result", "hemoglobin", "wbc", "platelets"]):
        return ("Lab reports compare your measured biological values against a standardized 'reference range'. "
                "For example, Hemoglobin indicates oxygen-carrying capacity, while White Blood Cells (WBC) reflect immune activity. "
                "Slight variations can occur based on hydration, time of day, and laboratory equipment; your doctor integrates these numbers with your clinical history for meaningful interpretation." + disclaimer)

    # General Educational Response
    return ("I can explain medical terminology, lab report concepts, wellness, nutrition, and exercise in simple terms. "
            "Please feel free to ask about any medical terms or health concepts you would like clarified." + disclaimer)
