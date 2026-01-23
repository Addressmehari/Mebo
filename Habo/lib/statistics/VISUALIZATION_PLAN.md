# Statistics Visualization Plan

## Analysis of Current State

The current statistics page visualizes **Behavior Consistency** (frequency) but fails to visualize **Intensity/Volume** (magnitude).

- **Boolean Habits**: ✅ **Correct**. Frequency (Streaks/Counts) is the only relevant metric.
- **Numeric Habits**: ❌ **Incomplete**. It visualizes how _often_ you did it, but not _how much_ (e.g., running 1km vs 10km looks the same).
- **Money Tracker**: ❌ **Incomplete**. It shows the current total, but not the _growth over time_.
- **Meter/Diary**: ❌ **Incomplete**. It shows frequency of entry, but not the _levels_ or _quality_ of the entry.

## Proposed "Simple & Different" Visualization Plan

The goal is to provide a "Life Dashboard" view that segregates **Consistency** (Did I show up?) from **Performance** (How did I do?).

### 1. Refactor Data Collection (`Statistics.dart`)

We need to extract detailed time-series data, not just aggregated counts.

- **Action**: Add `Map<DateTime, double> history` to the `StatisticsData` model.
- **Logic**: When iterating events, populate this map with the actual values (`progressValue`, `meterValue`, etc.) for every date.

### 2. New Component: `HabitTrendChart`

Replace or augment the monthly bar chart for non-boolean habits.

- **Visual**: A smooth Line Chart (Sparkline style) showing the last 30 days or 12 months.
- **For Numeric**: Y-Axis = Value (e.g., Pages, km).
- **For Money**: Y-Axis = Cumulative Balance.
- **For Meter**: Y-Axis = Level (0-100%).

### 3. Updated `StatisticsCard` Layout

Make the card dynamic based on `HabitType`.

#### **A. Boolean / Diary Habits (Focus: Consistency)**

_Keep current layout + enhancements._

- **Visual**: Large "Streak" counter.
- **Chart**: Monthly Frequency Bar Chart (Existing).
- **Addition**: "Completion Rate" (e.g., "85% this month").

#### **B. Numeric / Meter Habits (Focus: Performance)**

_New layout._

- **Visual**: "Average Value" (e.g., "5.2 km/day") instead of just streak.
- **Chart**: **Line Chart** showing value fluctuation over the month.
- **Insight**: "Total Volume" (e.g., "150km total").

#### **C. Money Tracker (Focus: Growth)**

_New layout._

- **Visual**: Current Balance (Large Text).
- **Chart**: **Area Chart** showing wealth accumulation over time.
- **Insight**: "Net Change" this month (+₹500).

### 4. Implementation Steps

1.  **Modify `StatisticsData`**: Add `Map<DateTime, double> valueHistory`.
2.  **Update `Statistics.calculateStatistics`**:
    - For `Numeric`, store `event[2]` (value).
    - For `Money`, calculate cumulative sum for each date.
3.  **Create `TrendLineChart` Widget**:
    - Use `fl_chart`.
    - Simple LineChart, minimalist grid.
4.  **Update `StatisticsCard`**:
    - Check `habit.type`.
    - If `Numeric/Money`, render `TrendLineChart`.
    - Else, render `MonthlyGraph`.

This approach ensures **every** data point (magnitude, balance, level) is visualized while keeping the UI simple by choosing the _right_ chart for the _right_ data type.
