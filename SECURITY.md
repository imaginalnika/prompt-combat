# Security

Configure services explicitly in the consuming application and keep credentials outside version control. Never ship permanent paid-service credentials in a distributable client; production deployments need an appropriate authenticated proxy or short-lived credentials.

Treat player input and model output as untrusted. Validate judge responses before applying them to game state, and test prompts against adversarial input. Review the chosen provider's data-handling terms before sending player text to a hosted model.

Run `python3 tools/verify.py` before submitting changes. Tests use synthetic data and mock providers without contacting paid services or recording a microphone.

Report suspected credentials privately to the repository maintainer rather than posting their values in a public issue.
