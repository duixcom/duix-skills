# Examples

Place sample portrait images under `assets/`.

```bash
# credentials
export DUIX_APP_ID="..."
export DUIX_APP_KEY="..."
export DUIX_API_KEY="..."   # for local image upload

duix-cli avatar check
duix-cli avatar create --coverImageUrl ./assets/demo_face.jpg --language English
# then select TTS and retry with --ttsName
duix-cli avatar create --coverImageUrl ./assets/demo_face.jpg --ttsName <selected> --language English
duix-cli avatar status <task_id> -c
```
