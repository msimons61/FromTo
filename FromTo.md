# I want to create a simple iOS app with tabViews

The app should calculate the "number of stocks" that can bought.
Use Decimal for more accurate calculations.
The app should run with full locale support.
The Decimal values should display and accept the thousand and decimal separators from the device's Region settings.
Every entered value should be persisted.
Use the best practices for SwiftUI.

Accept the following values

- "Available Amount": (decimal value 123.456,12 including thousand separators, when necessary) using the "From Currency" from Settings
- "Fixed Cost": (decimal value 123.456,12 including thousand separators, when necessary) using the "From Currency" from Settings
- "Variable Cost": (percentage, e.g. 0,1%) persist as 0.001, retrieve from Settings if empty or reset.
- "Maximum Cost": (decimal value 123.456,12 including thousand separators, when necessary) using the "From Currency" from Settings
- "Total Cost": (decimal value 123.456,12 including thousand separators, when necessary) using the "From Currency" from Settings
- "Investable Amount": (decimal value 123.456,12 including thousand separators, when necessary) using the "To Currency" from Settings
- "Stock price": (decimal value 123.456,12 including thousand separators, when necessary) using the "To Currency" from Settings
- "Number of Stocks": (integer value, including thousand separators, when necessary)
- "Invested Amount": (decimal value 123.456,12 including thousand separators, when necessary) using the "To Currency" from Settings

Calculate "Total Cost":
if "Maximum Cost" has a value
"Total Cost" = Minimum of ("Fixed Cost" + (Amount _ "Variable Cost"); "Maximum Cost")
else
"Total Cost" = "Fixed Cost" + (Amount _ "Variable Cost")
end if

Calculate "Investable Amount":

- "Investable Amount" = ("Available Amount" - "Total Cost") / "Currency rate"

Calculate "Number of Stock":

- "Number of Stock" = RoundDown("Investable Amount" / "Stock Price")

Calculate "Invested Amount":

- "Invested Amount" = Amount - "Total Cost"

## Tab 1)

### Section Investment Details

- "Available Amount"
- "Stock Price"

### Section Costs

The variables should be populated with the corresponding values from the Settings Tab, if they exist.
Add to section header "Costs" a circular button with Image(systemName: "arrow.trianglehead.2.counterclockwise.rotate.90") to reload
the values from Settings Section "Default Cost".

- "Fixed Cost"
- "Variable Cost"
- "Maximum Cost"
- "Total Cost"

### Section Results

- "Investable Amount" = ("Available Amount" - "Total Cost") / "Currency rate"
- "Number of Stock" = RoundDown("Investable Amount" / "Stock Price")
- "Invested Amount" to invest = "Number of Stock" \* "Stock Price"

## Tab 2) Accept two Decimal values From and To.

The app should calculate the difference is absolute value and percentage.

### Values

- "From" (decimal value 123.456,123456 including thousand separators)
- "To" (decimal value 123.456,123456 including thousand separators)

### Results

- Absolute Difference = "To" - "From" (decimal value 123.456,123456 including thousand separators)
- Relative Difference = ("To" - "From") / "From" (percentage, e.g. 1.234,45%)

Relative Difference should displayed as 150% for value 1,5

## Tab 3) Settings

### Appearance

- Display mode

### Currency

- "From currency" (list currency codes)
- "To currency" (list currency codes)
- "Currency rate" (decimal value 0,123456)

### Default Cost

- "Fixed Cost" (in "From currency")
- "Variable Cost" (percentage, e.g. 0,1%)
- "Maximum Cost" (in "From currency")
