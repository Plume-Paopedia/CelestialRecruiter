# Discord Integration Guide for Developers

This guide explains how the Discord notification system works and how to add notifications to other parts of the addon.

## Architecture

### Flow Diagram

```
[WoW Event Occurs]
       ↓
[Lua Module Detects Event]
       ↓
[Call DiscordQueue:QueueEvent()]
       ↓
[Event Saved to SavedVariables]
       ↓
[WoW Writes File to Disk]
       ↓
[Python Script Detects Change]
       ↓
[Parse Lua SavedVariables]
       ↓
[Send Discord Webhook]
       ↓
[Mark Event as Processed]
```

### Key Components

1. **Modules/DiscordQueue.lua**: Core queue management and event helpers
2. **ns.db.global.discordQueue**: Array of pending events in SavedVariables
3. **ns.db.profile.discord**: Settings (webhook URL, enabled flag, event toggles)
4. **Tools/discord_webhook.py**: External Python script that sends webhooks

## Adding Discord Notifications

### Step 1: Identify the Event Location

Find where the event occurs in your code. Examples:
- Player whispered: `Modules/Queue.lua` in `ns.Queue_Whisper()`
- Player invited: `Modules/Queue.lua` in `ns.Queue_Invite()`
- Queue added: `Core/DB.lua` in `ns.DB_QueueAdd()`
- Blacklisted: `Core/DB.lua` in `ns.DB_SetBlacklisted()`

### Step 2: Call the Appropriate Helper

After the event logic, add a Discord notification call:

```lua
-- Discord notification
if ns.DiscordQueue and ns.DiscordQueue.NotifyXXX then
  ns.DiscordQueue:NotifyXXX(playerName, additionalData)
end
```

**Important**: Always check if `ns.DiscordQueue` exists before calling methods!

### Existing Helper Functions

In `Modules/DiscordQueue.lua`, these helpers are available:

#### Guild Events
- `NotifyGuildJoin(playerName)`
- `NotifyGuildLeave(playerName)`

#### Recruitment
- `NotifyWhisperSent(playerName, template)`
- `NotifyInviteSent(playerName)`
- `NotifyPlayerJoined(playerName)`

#### Queue Management
- `NotifyQueueAdded(playerName)`
- `NotifyQueueRemoved(playerName, reason)`

#### Blacklist
- `NotifyBlacklisted(playerName, reason)`

#### Scanner
- `NotifyScannerStarted(levelRange)`
- `NotifyScannerStopped(stats)`
- `NotifyScannerComplete(stats)`

#### Summaries
- `NotifyDailySummary(stats)`
- `NotifySessionSummary(stats)`
- `NotifyAutoRecruiterComplete(stats)`

#### Alerts
- `NotifyLimitReached(limitType, current, max)`

### Step 3: Example Integration

#### Example 1: Add notification when scanner starts

In `Modules/Scanner.lua`, find where the scanner starts:

```lua
function ns.Scanner_Start()
  -- ... existing scanner start logic ...

  -- Discord notification
  if ns.DiscordQueue and ns.DiscordQueue.NotifyScannerStarted then
    local range = string.format("%d-%d", ns.db.profile.scanLevelMin, ns.db.profile.scanLevelMax)
    ns.DiscordQueue:NotifyScannerStarted(range)
  end
end
```

#### Example 2: Add notification for auto-recruiter completion

In `Modules/AutoRecruiter.lua`, find where the session completes:

```lua
function ns.AutoRecruiter_Complete()
  -- ... calculate stats ...

  -- Discord notification
  if ns.DiscordQueue and ns.DiscordQueue.NotifyAutoRecruiterComplete then
    ns.DiscordQueue:NotifyAutoRecruiterComplete({
      processed = totalProcessed,
      contacted = contacted,
      invited = invited,
      skipped = skipped,
      errors = errors
    })
  end
end
```

#### Example 3: Daily summary at logout

In `Core/Core.lua`, add a logout handler:

```lua
CR:RegisterEvent("PLAYER_LOGOUT", function()
  -- Generate daily summary
  if ns.DiscordQueue and ns.DiscordQueue.NotifyDailySummary then
    if ns.Statistics and ns.Statistics.GetDailyActivity then
      local activity = ns.Statistics:GetDailyActivity(1)
      local todayData = activity and activity[1]
      if todayData then
        ns.DiscordQueue:NotifyDailySummary({
          day = todayData.day or date("%Y-%m-%d"),
          scans = todayData.scans or 0,
          found = todayData.found or 0,
          contacted = todayData.contacted or 0,
          invited = todayData.invited or 0,
          joined = todayData.joined or 0
        })
      end
    end
  end
end)
```

## Creating Custom Event Types

### Step 1: Add Event Type Definition

In `Modules/DiscordQueue.lua`, add to the `EVENT_TYPES` table:

```lua
local EVENT_TYPES = {
  -- ... existing types ...

  -- Your new event type
  custom_event = {
    color = COLORS.BLUE,
    icon = "🔔",
    label = "Custom Event Label"
  },
}
```

### Step 2: Create Helper Function

In `Modules/DiscordQueue.lua`, add a helper function:

```lua
-- Custom Event
function DQ:NotifyCustomEvent(data)
    local fields = {}

    -- Build fields from data
    if data.field1 then
        table.insert(fields, {
            name = "Field 1",
            value = tostring(data.field1),
            inline = true
        })
    end

    -- Add more fields as needed

    self:QueueEvent("custom_event", {
        description = data.description or "Custom event occurred",
        fields = fields
    })
end
```

### Step 3: Add to Event Types UI

In `Modules/DiscordQueue.lua`, update `GetEventTypes()`:

```lua
function DQ:GetEventTypes()
    local categories = {
        -- ... existing categories ...
        {
            label = "Custom Events",
            events = {
                { id = "custom_event", label = "Custom event description" },
            }
        }
    }
    return categories
end
```

### Step 4: Initialize Default State

In `Modules/DiscordQueue.lua`, update `Init()`:

```lua
function DQ:Init()
    -- ... existing init code ...

    -- Set default for your custom event
    if discord.events.custom_event == nil then
        discord.events.custom_event = true  -- or false
    end
end
```

### Step 5: Use in Your Code

```lua
-- Somewhere in your module
if ns.DiscordQueue and ns.DiscordQueue.NotifyCustomEvent then
  ns.DiscordQueue:NotifyCustomEvent({
    description = "Something happened!",
    field1 = "Value 1",
    field2 = "Value 2"
  })
end
```

## Event Data Structure

Events in the queue have this structure:

```lua
{
  timestamp = 1234567890,      -- Unix timestamp (required)
  eventType = "player_joined", -- Event type ID (required)
  icon = "🎉",                 -- Emoji icon (optional)
  color = 3066993,             -- Discord embed color (required)
  title = "Event Title",       -- Embed title (required)
  description = "Details",     -- Embed description (optional)
  fields = {                   -- Array of embed fields (optional)
    {
      name = "Field Name",
      value = "Field Value",
      inline = true            -- Boolean (optional, default false)
    }
  }
}
```

## Testing Your Integration

### 1. Enable Discord in Settings

```lua
/run CelestialRecruiter.db.profile.discord.enabled = true
/run CelestialRecruiter.db.profile.discord.events.your_event_type = true
```

### 2. Trigger the Event

Perform the action that should trigger your notification.

### 3. Check the Queue

```lua
/dump CelestialRecruiter.db.global.discordQueue
```

You should see your event in the queue.

### 4. Run Python Script

Start the Python companion script to send the webhook:

```bash
python discord_webhook.py --config config.json
```

### 5. Verify in Discord

Check your Discord channel for the notification.

## Best Practices

### 1. Always Check for Module Existence

```lua
-- GOOD
if ns.DiscordQueue and ns.DiscordQueue.NotifyXXX then
  ns.DiscordQueue:NotifyXXX(data)
end

-- BAD (will error if DiscordQueue not loaded)
ns.DiscordQueue:NotifyXXX(data)
```

### 2. Use Contact Data When Available

```lua
local contact = ns.DB_GetContact(playerName)
-- Pass contact to helper for richer notifications
```

### 3. Provide Meaningful Descriptions

```lua
-- GOOD
description = "Joueur X a accepté l'invitation après 5 minutes"

-- BAD
description = "Event occurred"
```

### 4. Use Inline Fields for Related Data

```lua
fields = {
  { name = "Niveau", value = "70", inline = true },
  { name = "Classe", value = "Paladin", inline = true },
  { name = "Guilde", value = "None", inline = true }
}
```

### 5. Don't Spam Notifications

Use appropriate event toggles and rate limiting. Not every action needs a Discord notification!

### 6. Handle Missing Data Gracefully

```lua
local level = contact and contact.level or "?"
local class = contact and contact.classLabel or "Unknown"
```

## Performance Considerations

### Queue Size Limit

The queue is automatically limited to 100 events to prevent memory bloat. Older events are removed when the limit is reached.

### File Write Frequency

WoW writes SavedVariables to disk:
- At logout
- Every ~5 minutes during gameplay
- When `/reload` is issued

Events queued between writes will be batched.

### Rate Limiting

The Python script respects Discord's rate limit (30 requests per 60 seconds). Events will be delayed if the limit is reached, but won't be lost.

## Debugging

### Check Queue Contents

```lua
/run for i, e in ipairs(CelestialRecruiter.db.global.discordQueue) do print(i, e.eventType, e.timestamp) end
```

### Clear Queue

```lua
/run CelestialRecruiter.DiscordQueue:ClearAllEvents()
```

### Test Specific Event

```lua
/run CelestialRecruiter.DiscordQueue:NotifyWhisperSent("TestPlayer-Realm", "default")
```

### Force SavedVariables Write

```
/reload
```

Then check if the Python script picks up the event.

## Integration Checklist

When adding a new Discord notification:

- [ ] Identify the event location in code
- [ ] Decide which existing helper to use (or create new one)
- [ ] Add event type to EVENT_TYPES if creating custom event
- [ ] Add helper function if creating custom event
- [ ] Add to GetEventTypes() for UI if creating custom event
- [ ] Add initialization in Init() if creating custom event
- [ ] Add notification call with existence check
- [ ] Test in-game with `/dump` to verify queue
- [ ] Test with Python script to verify Discord delivery
- [ ] Update settings UI if needed

## Support

For questions or issues with Discord integration:
1. Check `discord_webhook.log` for Python script errors
2. Use `/dump CelestialRecruiter.db.global.discordQueue` to inspect queue
3. Verify settings in `/cr` → Reglages → Discord
4. Test webhook with the Test button in settings

## Future Enhancements

Potential improvements to the Discord integration:

1. **Rich embeds with thumbnails**: Add class icons, player avatars
2. **Webhook avatars**: Dynamic webhook avatar based on event type
3. **Thread support**: Send notifications to Discord threads
4. **Buttons/interactions**: Discord buttons for quick actions
5. **Slash commands**: Discord bot that responds to commands
6. **Two-way sync**: Respond to Discord messages in-game
7. **Multiple webhooks**: Different webhooks for different event types
8. **Webhook fallback**: Email notifications if webhook fails
9. **Event aggregation**: Batch similar events into one notification
10. **Custom templates**: User-defined notification templates

## Credits

- **Discord Integration**: Part of CelestialRecruiter 3.4.0+
- **Author**: Plume
- **Architecture**: Two-part system (Lua + Python)
