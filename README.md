# priority_receipt

Two ways to go detect priority receipt

# Method 1
  Predict the estimated next sales date and quantity from the raw data.
  
# Method 2 - Use the NPTRIF file as the input parameters
## Needed Parameters
- WAREHOUSE (FOR ID ONLY) (NPTRIF)
- ITEM_NUMBER  (FOR ID ONLY) (NPTRIF)
- RECEIPT_DATE  (FOR ID ONLY) (NPTRIF)
- PO_NUMBER (FOR ID ONLY) (NPTRIF)
- ETRN_NUMBER (FOR ID ONLY) (NPTRIF)
- DCI_MVTICK# (FOR ID ONLY) (NPTRIF)
- TOT_ALCLOC (NPTRIF)
- DAYS_FRM_SLE (NTPSLS)
- AVGD_BTW_SLE (NTPSLS)
- DAYS_BTW_SD (NTPSLS)
- SHIP_QTY_MN (NTPSLS)
- SHIP_QTY_SM (NTPSLS)
- SHIP_QTY_SD (NTPSLS)
- TOTAVL_QTY (NPTRIF)

