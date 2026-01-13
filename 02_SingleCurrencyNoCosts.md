Now we increasing the apps complexity.
In principle the functionality does not change

- Add a toggle "Double Currency" atop in section "Currency" in "Settings" view. Default value "True" (currently functionality remains unchanged).
- When "False" is selected:

  - Rename "From Currency" to "Currency".
  - Hide field "To Currency".
  - Hide field "Currency Rate".
  - Set value of "To Currency" to "From Currency".
  - "Current Rate" will automatically set to 1. Current functionality.

- Add a toggle "Apply Cost" atop in section "Currency" in "Settings" view. Default value "True" (currently functionality remains unchanged).
- When "False" is selected:
  - Hide field "Fixed Cost" and set value to 0.
  - Hide field "Variable Cost" and set value to 0.
  - Hide field "Maximum Cost" and set value to 0.

Behaviour in "Investment" view

- When "False" is selected for toggle "Double Currency"
  - Nothing changes
- When "False" is selected for toggle "Apply Cost"
  - Hide "Switch" button in "Costs" section header.
  - Hide every field in "Costs" section.
  - Always populate the fiels with the corresponding values from Settings view. (Necessary because fields are hidden and "Switch" button is hidden). Actually should be 0.

Are requirements clear?
