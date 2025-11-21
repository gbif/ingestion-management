#!/bin/bash
# Stats generation script for issue statistics workflow
# Can be run standalone for testing or called from GitHub Actions

set -e

# Parse command line arguments
UPDATE_README=false
QUIET=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --update-readme)
      UPDATE_README=true
      shift
      ;;
    --quiet)
      QUIET=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [ "$QUIET" = false ]; then
  echo "=== Testing Issue Statistics Workflow Logic ==="
  echo ""
fi

# Check for gh CLI
if ! command -v gh &> /dev/null; then
    echo "Error: gh CLI not found. Please install it from https://cli.github.com/"
    exit 1
fi

# Check for jq
if ! command -v jq &> /dev/null; then
    echo "Error: jq not found. Installing..."
    # On Windows with choco: choco install jq
    # On Windows with scoop: scoop install jq
    exit 1
fi

# Check for Python
if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
    echo "Error: Python not found."
    exit 1
fi

PYTHON_CMD=$(command -v python3 || command -v python)

# Check for matplotlib and pandas
echo "Checking Python dependencies..."
$PYTHON_CMD -c "import matplotlib, pandas" 2>/dev/null || {
    echo "Installing matplotlib and pandas..."
    $PYTHON_CMD -m pip install matplotlib pandas
}

echo "✓ All dependencies found"
echo ""

# Define labels
LABELS=(
    "occurrenceID - publisher changed back"
    "occurrenceID - resumes ingestion with new"
    "occurrenceID - migrated"
    "occurrenceID - checks disabled"
    "occurrenceID - large change in record counts"
)

# Create data directory
mkdir -p stats_data

# Fetch issue data
echo "Fetching issue data from GitHub..."
for label in "${LABELS[@]}"; do
    echo "  Processing label: $label"
    gh issue list --label "$label" --state all --limit 1000 --json number,state,closedAt,labels > "stats_data/${label// /_}.json"
done

echo "✓ Issue data fetched"
echo ""

# Create combined time series dataset
echo "Creating time series dataset..."
echo "[]" > stats_data/time_series.json
for label in "${LABELS[@]}"; do
    jq --arg lbl "$label" '.[] | select(.closedAt != null) | {label: $lbl, closedAt: .closedAt}' "stats_data/${label// /_}.json" >> stats_data/time_series.json
done

# Wrap in array
jq -s '.' stats_data/time_series.json > stats_data/time_series_wrapped.json
mv stats_data/time_series_wrapped.json stats_data/time_series.json

# Create publisher time series dataset
echo "Creating publisher time series dataset..."
echo "[]" > stats_data/publisher_time_series.json
for label in "${LABELS[@]}"; do
    # Extract closed issues with their labels and closedAt date
    # Find the pub: label (publisher UUID) for each issue
    jq --arg lbl "$label" '
      .[] | 
      select(.closedAt != null) | 
      . as $issue |
      (.labels[] | select(.name | startswith("pub:")) | .name) as $pub |
      {label: $lbl, closedAt: $issue.closedAt, publisher: $pub}
    ' "stats_data/${label// /_}.json" >> stats_data/publisher_time_series.json
done

# Wrap in array
jq -s '.' stats_data/publisher_time_series.json > stats_data/publisher_time_series_wrapped.json
mv stats_data/publisher_time_series_wrapped.json stats_data/publisher_time_series.json

echo "✓ Time series data created"
echo ""

# Generate statistics table
echo "Generating statistics table..."
echo "## Issue Statistics" > stats_data/table.md
echo "" >> stats_data/table.md
echo "Last updated: $(date -u +"%Y-%m-%d %H:%M UTC" 2>/dev/null || date +"%Y-%m-%d %H:%M UTC")" >> stats_data/table.md
echo "" >> stats_data/table.md
echo "### Closed Issues by Label" >> stats_data/table.md
echo "" >> stats_data/table.md
echo "| Label | Closed Issues |" >> stats_data/table.md
echo "|-------|---------------|" >> stats_data/table.md

for label in "${LABELS[@]}"; do
    closed_count=$(jq '[.[] | select(.state == "CLOSED")] | length' "stats_data/${label// /_}.json")
    echo "| $label | $closed_count |" >> stats_data/table.md
done

echo "" >> stats_data/table.md
echo "### Issue Closure Timeline" >> stats_data/table.md
echo "" >> stats_data/table.md
echo "![Issue Closure Timeline](stats_timeline.png)" >> stats_data/table.md
echo "" >> stats_data/table.md
echo "### Unique Publishers per Month" >> stats_data/table.md
echo "" >> stats_data/table.md
echo "![Unique Publishers per Month](stats_publishers_timeline.png)" >> stats_data/table.md

echo "✓ Statistics table generated"
echo ""

# Create visualization
echo "Creating time series visualization..."
$PYTHON_CMD << 'PYTHON_SCRIPT'
import json
import matplotlib.pyplot as plt
import pandas as pd
from datetime import datetime
from collections import defaultdict

# Load time series data
with open('stats_data/time_series.json', 'r') as f:
    data = json.load(f)

# Filter out non-dict items (like empty arrays)
data = [item for item in data if isinstance(item, dict) and 'closedAt' in item and 'label' in item]

# Process data into monthly counts
monthly_counts = defaultdict(lambda: defaultdict(int))

for item in data:
    if item.get('closedAt'):
        closed_date = datetime.fromisoformat(item['closedAt'].replace('Z', '+00:00'))
        month_key = closed_date.strftime('%Y-%m')
        label = item['label']
        monthly_counts[month_key][label] += 1

# Convert to DataFrame
df_data = []
for month, labels in sorted(monthly_counts.items()):
    row = {'month': month}
    row.update(labels)
    df_data.append(row)

if df_data:
    df = pd.DataFrame(df_data)
    df['month'] = pd.to_datetime(df['month'])
    df = df.set_index('month')
    df = df.fillna(0)
    
    # Create plot
    fig, ax = plt.subplots(figsize=(12, 6))
    df.plot(ax=ax, marker='o', linewidth=2)
    
    ax.set_xlabel('Month', fontsize=12)
    ax.set_ylabel('Number of Issues Closed', fontsize=12)
    ax.set_title('Issue Closure Timeline by Label', fontsize=14, fontweight='bold')
    ax.legend(title='Label', bbox_to_anchor=(1.05, 1), loc='upper left', fontsize=9)
    ax.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('stats_timeline.png', dpi=150, bbox_inches='tight')
    print("✓ Time series plot created successfully")
else:
    # Create empty plot if no data
    fig, ax = plt.subplots(figsize=(12, 6))
    ax.text(0.5, 0.5, 'No closed issues yet', 
            ha='center', va='center', fontsize=14)
    ax.set_title('Issue Closure Timeline by Label', fontsize=14, fontweight='bold')
    plt.savefig('stats_timeline.png', dpi=150, bbox_inches='tight')
    print("✓ Created placeholder plot (no data)")
PYTHON_SCRIPT

echo ""

# Create publisher timeline visualization
echo "Creating publisher timeline visualization..."
$PYTHON_CMD << 'PYTHON_SCRIPT'
import json
import matplotlib.pyplot as plt
import pandas as pd
from datetime import datetime
from collections import defaultdict

# Load publisher time series data
with open('stats_data/publisher_time_series.json', 'r') as f:
    data = json.load(f)

# Filter out non-dict items
data = [item for item in data if isinstance(item, dict) and 'closedAt' in item and 'label' in item and 'publisher' in item]

# Process data into monthly unique publisher counts
monthly_publishers = defaultdict(lambda: defaultdict(set))

for item in data:
    if item.get('closedAt') and item.get('publisher'):
        closed_date = datetime.fromisoformat(item['closedAt'].replace('Z', '+00:00'))
        month_key = closed_date.strftime('%Y-%m')
        label = item['label']
        publisher = item['publisher']
        monthly_publishers[month_key][label].add(publisher)

# Convert to DataFrame with counts
df_data = []
for month, labels in sorted(monthly_publishers.items()):
    row = {'month': month}
    for label, publishers in labels.items():
        row[label] = len(publishers)
    df_data.append(row)

if df_data:
    df = pd.DataFrame(df_data)
    df['month'] = pd.to_datetime(df['month'])
    df = df.set_index('month')
    df = df.fillna(0)
    
    # Create plot
    fig, ax = plt.subplots(figsize=(12, 6))
    df.plot(ax=ax, marker='o', linewidth=2)
    
    ax.set_xlabel('Month', fontsize=12)
    ax.set_ylabel('Number of Unique Publishers', fontsize=12)
    ax.set_title('Unique Publishers per Month by Label', fontsize=14, fontweight='bold')
    ax.legend(title='Label', bbox_to_anchor=(1.05, 1), loc='upper left', fontsize=9)
    ax.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('stats_publishers_timeline.png', dpi=150, bbox_inches='tight')
    print("✓ Publisher timeline plot created successfully")
else:
    # Create empty plot if no data
    fig, ax = plt.subplots(figsize=(12, 6))
    ax.text(0.5, 0.5, 'No publisher data yet', 
            ha='center', va='center', fontsize=14)
    ax.set_title('Unique Publishers per Month by Label', fontsize=14, fontweight='bold')
    plt.savefig('stats_publishers_timeline.png', dpi=150, bbox_inches='tight')
    print("✓ Created placeholder publisher plot (no data)")
PYTHON_SCRIPT

echo ""

# Update README if requested
if [ "$UPDATE_README" = true ]; then
  echo "Updating README..."
  # Read current README
  if [ -f README.md ]; then
    # Check if stats section exists
    if grep -q "## Issue Statistics" README.md; then
      # Remove old stats section (from ## Issue Statistics to next ## or end of file)
      sed -i '/## Issue Statistics/,/^## \|^$/d' README.md
    fi
    
    # Append new stats section
    cat stats_data/table.md >> README.md
  else
    # Create new README with stats
    cat stats_data/table.md > README.md
  fi
  echo "✓ README updated"
  echo ""
fi

if [ "$QUIET" = false ]; then
  echo "=== README Update Preview ==="
  echo ""
  cat stats_data/table.md
  echo ""
  echo "=== Files Generated ==="
  echo "  ✓ stats_data/table.md - Statistics table"
  echo "  ✓ stats_timeline.png - Time series chart (closed issues)"
  echo "  ✓ stats_publishers_timeline.png - Time series chart (unique publishers)"
  echo ""
  
  if [ "$UPDATE_README" = false ]; then
    echo "To update README.md, run with --update-readme flag"
    echo ""
  fi
  
  echo "=== Test Complete ==="
fi
