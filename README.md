# priority_receipt

Two ways to go detect priority receipt

# Method 1
  Predict the estimated next sales date and quantity from the raw data.
  
# Method 2 - Use the NPTRIF file as the input parameters
## Needed Parameters
- TOT_ALCLOC - total allocated at location (NPTRIF)
- DAYS_FRM_SLE (NTPSLS)
- AVGD_BTW_SLE (NTPSLS)
- DAYS_BTW_SD (NTPSLS)
- SHIP_QTY_MN (NTPSLS)
- SHIP_QTY_SM (NTPSLS)
- SHIP_QTY_SD (NTPSLS)
- TOTAVL_QTY (NPTRIF)

