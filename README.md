# transfer.sh-omz-plugin
A plugin for ohmyzsh that lets you easily upload files/folders to your personal transfer.sh instance 

### Requirements: 
  - [ohmyzsh](https://github.com/ohmyzsh/ohmyzsh)
  - Utilities: `zip curl grep mktemp tr jq awk`
  - Using HTTP auth with transfer.sh to limit who can upload

### Steps:
  1. Download the `trs` folder with the plugin and move it to `$HOME/.oh-my-zsh/custom/plugins/`
  2. Add `trs` to plugins in `$HOME/.zshrc`  ([Plugins reference](https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins))
  3. Export these environment variables:
     - `TRANSFER_BASE_URL` (include http prefix & remove trailing slash)
     - `TRANSFER_HTTP_USER`
     - `TRANSFER_HTTP_PASS`
  4. `omz reload` to activate new plugin


### Usage:
  - Basic upload: `trs /path/to/file.txt`
  - Call `trs` on its own to see optional arguments
  - By default, all uploads will save a timestamp, upload link, and delete token in `$HOME/.transfer_history`

***
### Example response:
```
{
  "web_url": "https://tr.example.com/PaY1BiNX25/myimage.jpg",
  "inline_url": "https://tr.example.com/inline/PaY1BiNX25/myimage.jpg",
  "download_url": "https://tr.example.com/get/PaY1BiNX25/myimage.jpg",
  "delete_token": "u8qnikihLx2V5N45oC93"
}
```
