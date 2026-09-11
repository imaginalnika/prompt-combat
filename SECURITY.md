# Security and release hygiene

No credentials, personal accounts, original application assets, recordings, or private endpoints belong in this repository. Configure services explicitly in the consuming application and keep credentials outside version control. Never ship permanent paid-service credentials in a distributable client; production deployments need an appropriate authenticated proxy or short-lived credentials.

Before a release:

1. Review every staged file, including hidden files, documentation, examples, generated artifacts, and Git metadata.
2. Scan both the working tree and Git history using a secret scanner with redacted output.
3. Check project-specific names/content separately; secret scanners do not identify intellectual property.
4. Run `python3 tools/verify.py`.
5. Confirm licensing authority for all contributed code and preserve third-party notices.

Tests use neutral synthetic data and mock providers. They must not contact paid services or record a microphone implicitly. No scan can prove a universal negative; a clean scan does not replace source review.

Report suspected credentials privately to the repository maintainer rather than posting their values in a public issue.
