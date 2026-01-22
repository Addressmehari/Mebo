# 24-Hour Tasks - Instagram Stories UI

## Overview
24-hour tasks now appear as **Instagram-style stories** at the top of your home screen! Each task shows up as a circular story with:
- **Progress ring** showing time elapsed
- **Time remaining badge** (hours or minutes)
- **Color-coded indicators**:
  - 🟢 **Green**: More than 12 hours remaining
  - 🟠 **Orange**: 6-12 hours remaining
  - 🔴 **Red**: Less than 6 hours remaining

## Visual Design

### Story Circle Features
1. **Outer Progress Ring**: Fills clockwise to show elapsed time
2. **Gradient Circle**: Beautiful gradient background
3. **Clock Icon**: Central icon indicating temporal nature
4. **Time Badge**: Shows "12h" or "45m" remaining
5. **Habit Title**: Below the circle (truncated if too long)
6. **Glow Effect**: Subtle shadow for depth

### Layout
```
┌─────────────────────────────────┐
│  📅 Calendar Header              │
├─────────────────────────────────┤
│  ⭕ ⭕ ⭕ ← 24hr Tasks (Stories) │
│  12h 8h  3h                      │
├─────────────────────────────────┤
│  📁 Category Filter (optional)   │
├─────────────────────────────────┤
│  📋 Regular Habits List          │
│  ┌─────────────────────┐         │
│  │ Habit 1             │         │
│  └─────────────────────┘         │
│  ┌─────────────────────┐         │
│  │ Habit 2             │         │
│  └─────────────────────┘         │
└─────────────────────────────────┘
```

## Implementation Details

### New Files Created
1. **`hour_24_stories.dart`**: The stories widget
   - `Hour24Stories`: Container widget
   - `_StoryCircle`: Individual story item
   - `_ProgressRingPainter`: Custom painter for progress ring

### Modified Files
1. **`calendar_column.dart`**:
   - Separates 24-hour habits from regular habits
   - Shows stories at top
   - Filters out 24-hour habits from main list

### Features
- **Horizontal Scrolling**: Swipe to see all 24-hour tasks
- **Tap to Edit**: Tap any story to edit that habit
- **Auto-hide**: Stories section disappears when empty
- **Real-time Updates**: Progress ring updates on rebuild

## User Flow

### Creating a 24-Hour Task
1. Tap the **+** button
2. Enter habit details
3. Toggle **"24-Hour Task"** ON
4. Save

### Viewing Stories
1. Open the app
2. See circular stories at top (if any exist)
3. Scroll horizontally to see all
4. Tap a story to edit/view details

### Time Progression
- **0-12 hours**: 🟢 Green ring, relaxed state
- **12-18 hours**: 🟠 Orange ring, needs attention  
- **18-24 hours**: 🔴 Red ring, urgent!
- **After 24 hours**: Auto-deleted on next day change

## Visual Indicators

### Progress Ring
- **Empty (0%)**: Just created
- **Half Full (50%)**: 12 hours passed
- **Almost Full (95%)**: Nearly expired  
- **Smooth Animation**: Progress fills clockwise from top

### Time Badge
- **Shows Hours**: When > 60 minutes remain ("12h", "8h")
- **Shows Minutes**: When < 60 minutes remain ("45m", "12m")
- **Color Matches Ring**: Green → Orange → Red

## Technical Notes

### Performance
- Uses `CustomPainter` for smooth drawing
- Minimal rebuilds
- Efficient filtering

### Accessibility
- Tappable stories
- Clear visual hierarchy
- Readable text

### Edge Cases Handled
- Empty stories list (hides section)
- Very long habit names (truncated)
- Multiple stories (scrollable)
- No 24-hour habits + no regular habits (shows empty state)

## Comparison: Before vs After

### Before
```
All habits mixed together in one list
❌ Hard to spot temporary tasks
❌ No visual urgency indicator
❌ Manual cleanup needed
```

### After
```
24-hour tasks at top in story circles
✅ Instantly visible and distinctive
✅ Time remaining always visible
✅ Auto-cleanup after 24 hours
✅ Beautiful, intuitive UI
```

## Tips for Users
1. **Daily Planning**: Create multiple 24-hour tasks each morning
2. **Quick Glance**: Check stories to see urgent tasks
3. **Color Coding**: Red = do it now, Orange = soon, Green = plenty of time
4. **Swipe Through**: Scroll stories to see all temporary tasks

## Future Enhancements (Ideas)
- Story "tap and hold" for quick completion
- Animation when task is completed
- Confetti effect when all stories completed
- Story preview on long press
- Batch create stories from templates
- Export stories as images

Enjoy your beautiful new 24-hour task stories! 📱✨
