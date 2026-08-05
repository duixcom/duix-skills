# Examples

Place sample portrait images under `assets/` (aspect ratio must be **16:9** or **9:16**).

```bash
# credentials (avatar does not need DUIX_API_KEY)
export DUIX_APP_ID="..."
export DUIX_APP_KEY="..."

duix-cli avatar check
duix-cli avatar create --coverImageUrl ./assets/demo_face.jpg --language English
# If need_select=true: STOP. Show options to the user. Never auto-pick.
# After the user selects:
duix-cli avatar create --coverImageUrl ./assets/demo_face.jpg --ttsName <user-selected> --language English
duix-cli avatar status <task_id> -c
```
