# GitHub Actions IPA Release Guide

This guide details how to configure GitHub Actions to build a signed iOS `.ipa` distribution package.

---

## 1. Why IPA is Not Built on Standard Commits
iOS apps must be signed with an Apple-approved Certificate and Provisioning Profile. The default GitHub runner cannot sign binaries without:
1. **Apple Developer Credentials**: A distribution certificate (`.p12`) and associated provisioning profile.
2. **Access Control**: These files are sensitive and must be stored as encrypted GitHub Repository Secrets, not committed to the repository directly.
3. **Manual Trigger**: Building IPAs on every push consumes macOS action runner minutes rapidly. Therefore, building is configured as a manual trigger via `workflow_dispatch`.

---

## 2. GitHub Secrets Required
To enable the **iOS Signed IPA** workflow, go to your repository on GitHub: `Settings > Secrets and variables > Actions`, and add the following repository secrets:

| Secret Name | Description | Example / Target |
| :--- | :--- | :--- |
| `BUILD_CERTIFICATE_BASE64` | Base64-encoded string of your Apple Distribution `.p12` certificate. | `MIIDiwYJKoZIhvcNAQcCoIIDfDCCA3gCAQExADALBgkq...` |
| `P12_PASSWORD` | The password you used when exporting the `.p12` certificate. | `my-secure-cert-password` |
| `BUILD_PROVISION_PROFILE_BASE64` | Base64-encoded string of your App's `.mobileprovision` file. | `MIIF8AYJKoZIhvcNAQcCoIIF4TCCBdECAQExADALBgkq...` |
| `KEYCHAIN_PASSWORD` | A temporary password for the runner to create a temporary keychain. | `temp-runner-keychain-pass` |

---

## 3. How to Generate Base64 Strings
Do NOT commit `.p12` or `.mobileprovision` files directly to Git. Instead, open your local terminal on macOS and convert them into base64 strings:

* **Convert Certificate**:
  ```bash
  base64 -i my_certificate.p12 -o certificate_base64.txt
  ```
* **Convert Provisioning Profile**:
  ```bash
  base64 -i my_profile.mobileprovision -o profile_base64.txt
  ```

Copy the text contents of the generated `.txt` files and paste them into the respective GitHub Secrets fields.

---

## 4. How to Trigger the IPA Build Workflow
1. Go to your GitHub Repository webpage.
2. Click on the **Actions** tab at the top.
3. In the left-hand sidebar, select the workflow: **iOS Signed IPA**.
4. Click the **Run workflow** dropdown on the right side.
5. Select the branch (e.g. `main`) and click **Run workflow**.
6. Once completed, download the `.ipa` file from the **Artifacts** section at the bottom of the run summary page.

---

## 5. Local Alternatives
If you do not want to set up GitHub Secrets, you can build the signed IPA locally on a macOS machine:

```bash
cd flutter_app
flutter build ipa --release
```

Ensure Xcode is logged into your Apple Developer account and has downloaded the signing assets beforehand.

---

## 6. Security Reminders
* **Never commit** `.p12` files, private keys (`.pem`, `.p8`), `.mobileprovision` profile files, or custom `ExportOptions.plist` structures with raw provisioning IDs.
* Use a **Private GitHub Repository** during initial development to protect system architectures and research details.
