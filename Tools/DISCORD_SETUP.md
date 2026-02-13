# Discord Webhook Setup Guide

This guide will help you set up real-time Discord notifications for CelestialRecruiter guild events.

## Overview

CelestialRecruiter uses a two-part system for Discord notifications:

1. **WoW Addon (Lua)**: Queues events to SavedVariables (persistent storage)
2. **Python Companion Script**: Monitors SavedVariables and sends Discord webhooks

This architecture is necessary because WoW addons run in a sandboxed environment and cannot make HTTP requests directly.

## Prerequisites

- Python 3.7+ installed on your PC
- A Discord server where you have Manage Webhooks permission
- CelestialRecruiter addon installed in WoW

## Step 1: Create Discord Webhook

1. Open your Discord server
2. Go to **Server Settings** → **Integrations** → **Webhooks**
3. Click **New Webhook**
4. Configure the webhook:
   - **Name**: CelestialRecruiter
   - **Channel**: Choose the channel for notifications (e.g., #recruitment)
   - **Icon**: Optional custom icon
5. Click **Copy Webhook URL** - you'll need this later
6. Save your changes

## Step 2: Install Python Dependencies

Open Command Prompt (Windows) or Terminal (Mac/Linux) and run:

```bash
pip install requests watchdog
```

- `requests`: For sending HTTP requests to Discord
- `watchdog`: For monitoring file changes (optional but recommended)

## Step 3: Configure the Companion Script

1. Navigate to the Tools directory:
   ```
   C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\CelestialRecruiter\Tools\
   ```

2. Create a `config.json` file with the following content:

```json
{
  "savedvariables_path": "C:\\Program Files (x86)\\World of Warcraft\\_retail_\\WTF\\Account\\YOUR_ACCOUNT\\SavedVariables\\CelestialRecruiterDB.lua",
  "webhook_url": "YOUR_DISCORD_WEBHOOK_URL_HERE",
  "check_interval": 5,
  "rate_limit_delay": 2
}
```

**Important**: Replace the following:
- `YOUR_ACCOUNT`: Your actual WoW account name (find it in `WTF\Account\` folder)
- `YOUR_DISCORD_WEBHOOK_URL_HERE`: The webhook URL you copied in Step 1

**Note**: Use double backslashes (`\\`) in the path for Windows!

3. To auto-generate a config template, run:
   ```bash
   python discord_webhook.py --create-config
   ```

## Step 4: Configure In-Game Settings

1. Launch World of Warcraft
2. Open CelestialRecruiter: `/cr`
3. Go to **Reglages (Settings)** tab
4. Scroll to **Notifications Discord** section
5. Paste your Discord webhook URL in the **URL Webhook Discord** field
6. Check **Activer les notifications Discord**
7. Select which event types you want to receive:
   - Guild events (joins, leaves, promotions)
   - Recruitment events (whispers, invites, accepts)
   - Queue management (players added/removed)
   - Scanner activity
   - Daily summaries
8. Click **Test** to verify the connection

## Step 5: Start the Companion Script

### Option A: Manual Start (Recommended for Testing)

Open Command Prompt in the Tools directory and run:

```bash
python discord_webhook.py
```

You should see:
```
[INFO] Starting file watching mode
[INFO] Watching: C:\...\CelestialRecruiterDB.lua
[INFO] Webhook: https://discord.com/api/webhooks/...
```

### Option B: Background Start (Windows Task Scheduler)

To run the script automatically:

1. Open **Task Scheduler**
2. Create a new task:
   - **Trigger**: At log on
   - **Action**: Start a program
     - Program: `pythonw.exe` (silent version)
     - Arguments: `"C:\...\discord_webhook.py"`
     - Start in: `"C:\...\Tools"`
3. Save and enable the task

### Option C: Run on WoW Launch (Advanced)

Create a batch file `start_discord_webhook.bat`:

```batch
@echo off
cd /d "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\CelestialRecruiter\Tools"
start /B pythonw.exe discord_webhook.py
```

Place this batch file in your WoW directory and run it before launching WoW.

## Step 6: Test the Integration

1. Make sure the Python script is running
2. In WoW, open CelestialRecruiter (`/cr`)
3. Go to Settings → Discord section
4. Click the **Test** button
5. Check your Discord channel - you should see a test message!

If the test works, try these real events:
- Add a player to queue → Discord notification
- Send a whisper → Discord notification
- Invite a player → Discord notification

## Event Types

The system supports these event categories:

### Guild Events
- **guild_join**: New member joins guild
- **guild_leave**: Member leaves guild
- **guild_promote**: Member promoted
- **guild_demote**: Member demoted

### Recruitment Events
- **player_whispered**: Recruitment message sent
- **player_invited**: Guild invitation sent
- **player_joined**: Player joined after recruitment
- **queue_added**: Player added to recruitment queue
- **queue_removed**: Player removed from queue
- **player_blacklisted**: Player added to blacklist

### Scanner & Auto-Recruiter
- **scanner_started**: Scanner began searching
- **scanner_stopped**: Scanner stopped
- **scanner_complete**: Scan finished successfully
- **autorecruiter_complete**: Auto-recruiter session finished

### Summaries & Alerts
- **daily_summary**: Daily recruitment statistics
- **session_summary**: Session statistics at logout
- **limit_reached**: Rate limit or quota reached

## Customization

### Adjust Check Interval

In `config.json`, change `check_interval` (in seconds):
- Lower values (3-5s): More responsive, higher CPU usage
- Higher values (10-15s): Less responsive, lower CPU usage

### Adjust Rate Limiting

The script respects Discord's rate limit (30 requests per 60 seconds). You can adjust the delay between webhooks:
- `rate_limit_delay`: Minimum seconds between webhook sends (default: 2)

### Custom Event Filtering

Enable/disable specific event types in-game:
1. Open CelestialRecruiter settings
2. Scroll to Discord section
3. Toggle individual event types on/off

## Troubleshooting

### "No events received in Discord"

1. Check the Python script is running (you should see log messages)
2. Verify the webhook URL is correct in both config.json and in-game settings
3. Make sure "Activer les notifications Discord" is checked in-game
4. Check that specific event types are enabled
5. Try the Test button in settings

### "SavedVariables file not found"

1. Verify the path in `config.json` is correct
2. Make sure you've logged into WoW at least once with CelestialRecruiter enabled
3. Check that the account name matches your actual WoW account folder name

### "Rate limit errors"

If you see rate limit warnings:
1. Increase `rate_limit_delay` in config.json
2. Disable some event types to reduce notification volume
3. The script will automatically retry after the rate limit expires

### "Python script crashes"

1. Check the log file: `discord_webhook.log`
2. Verify all dependencies are installed: `pip install requests watchdog`
3. Try running with `--test` flag: `python discord_webhook.py --test`

### "Test webhook works but real events don't"

1. Perform an actual recruitment action in-game
2. Wait 5-10 seconds for the file to be written by WoW
3. Check the script console for "Processing X pending events"
4. If still no events, check that event types are enabled in settings

## Advanced Usage

### Multiple WoW Accounts

Create separate config files for each account:

```bash
python discord_webhook.py --config config_account1.json
python discord_webhook.py --config config_account2.json
```

### Custom Logging

Edit the Python script to change log level:

```python
logging.basicConfig(
    level=logging.DEBUG,  # Change to DEBUG for verbose logs
    ...
)
```

### Manual Queue Processing

To process the queue once and exit:

```bash
python discord_webhook.py --config config.json
# Press Ctrl+C after one cycle
```

### Clear All Queued Events

In WoW, run this Lua command in chat:

```lua
/run CelestialRecruiter.DiscordQueue:ClearAllEvents()
```

## Security Notes

1. **Never share your webhook URL publicly** - anyone with the URL can send messages to your Discord channel
2. Keep `config.json` secure and don't commit it to version control
3. If your webhook is compromised, delete it in Discord and create a new one
4. The webhook URL contains sensitive credentials - treat it like a password

## Performance

The companion script is lightweight and uses minimal resources:
- CPU: <1% when idle
- Memory: ~20-30 MB
- Network: Only when sending webhooks (typically <1 KB per event)

File watching mode (with `watchdog`) is more efficient than polling mode.

## Support

If you encounter issues:
1. Check the log file: `discord_webhook.log`
2. Enable debug logging for more details
3. Verify configuration in both the script and in-game settings
4. Test the webhook URL manually with the `--test` flag

For bug reports or feature requests, contact the addon author.

## Credits

- **Addon Author**: Plume
- **Discord Integration**: Part of CelestialRecruiter 3.4.0+
- **Python Script**: Compatible with Windows, Mac, and Linux

Enjoy your real-time Discord notifications!
