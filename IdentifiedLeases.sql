/* Step 1 dividing CCOD into unique and non-unique

Some of the addresses that correspond to only 1 lease in Reg Leases (reg prop descr: uniqueidentifier), are 1:m (pty_addr: title no) in CCOD 
(at the end of November 2020 they are 222 such registeraddresses), 
so I am diving the sample into 1:1 and 1:m address:title_no relationship for both leashold and freehold title numbers
*/
-- unique for leaseholds
SELECT a.*
INTO   #ccoduniqueaddressleasehold
FROM   (SELECT *
        FROM   [LandReg].[dbo].[commercialcorporateownershiplatest]
        WHERE  tenure = 'leasehold') a
       INNER JOIN (SELECT pty_addr
                   FROM   (SELECT DISTINCT TITLE_NO,
                                           PTY_ADDR
                           FROM   (SELECT *
                                   FROM
                          [LandReg].[dbo].[commercialcorporateownershiplatest]
                                   WHERE  tenure = 'leasehold') u) g
                   GROUP  BY pty_addr
                   HAVING Count(title_no) = 1) z
               ON a.PTY_ADDR = z.PTY_ADDR

-- unique for freeholds
SELECT a.*
INTO   #ccoduniqueaddressfreehold
FROM   (SELECT *
        FROM   [LandReg].[dbo].[commercialcorporateownershiplatest]
        WHERE  tenure = 'freehold') a
       INNER JOIN (SELECT pty_addr
                   FROM   (SELECT DISTINCT TITLE_NO,
                                           PTY_ADDR
                           FROM   (SELECT *
                                   FROM
                          [LandReg].[dbo].[commercialcorporateownershiplatest]
                                   WHERE  tenure = 'freehold') u) g
                   GROUP  BY pty_addr
                   HAVING Count(title_no) = 1) z
               ON a.PTY_ADDR = z.PTY_ADDR

-- non-unique for leaseholds
SELECT a.*
INTO   #ccodnonuniqueaddressleasehold
FROM   (SELECT *
        FROM   [LandReg].[dbo].[commercialcorporateownershiplatest]
        WHERE  tenure = 'leasehold') a
       INNER JOIN (SELECT pty_addr
                   FROM   (SELECT DISTINCT TITLE_NO,
                                           PTY_ADDR
                           FROM   (SELECT *
                                   FROM
                          [LandReg].[dbo].[commercialcorporateownershiplatest]
                                   WHERE  tenure = 'leasehold') u) g
                   GROUP  BY pty_addr
                   HAVING Count(title_no) > 1) z
               ON a.PTY_ADDR = z.PTY_ADDR

-- non-unique for freeholds
SELECT a.*
INTO   #ccodnonuniqueaddressfreehold
FROM   (SELECT *
        FROM   [LandReg].[dbo].[commercialcorporateownershiplatest]
        WHERE  tenure = 'freehold') a
       INNER JOIN (SELECT pty_addr
                   FROM   (SELECT DISTINCT TITLE_NO,
                                           PTY_ADDR
                           FROM   (SELECT *
                                   FROM
                          [LandReg].[dbo].[commercialcorporateownershiplatest]
                                   WHERE  tenure = 'freehold') u) g
                   GROUP  BY pty_addr
                   HAVING Count(title_no) > 1) z
               ON a.PTY_ADDR = z.PTY_ADDR

/* Step 2 Numbering and pivoting CCOD company data
Since companies sharing the same title number are arranged "vertically" in the CCOD, 
I want to reshape the data to a horizontal layout, so that there's only 1 line per title_no, like in overseas CCOD

Note that we are also selecting Price Paid - this is for further matching on price in Step 8

*/
--numbering the rows - freehold unique
SELECT *,
       DENSE_RANK()
         OVER (
           partition BY title_no
           ORDER BY co_reg_no ) AS field_id
INTO   #id_ed_fh_unique
FROM   #ccoduniqueaddressfreehold

--pivoting - freehold unique
SELECT title_no,
       PTY_ADDR,
       [Price Paid],
       Max(CASE
             WHEN field_id = 1 THEN CO_REG_NO
             ELSE NULL
           END) AS LL_CO_REG_NO_1,
       Max(CASE
             WHEN field_id = 2 THEN CO_REG_NO
             ELSE NULL
           END) AS LL_CO_REG_NO_2,
       Max(CASE
             WHEN field_id = 1 THEN NON_PI_NAME
             ELSE NULL
           END) AS LL_NON_PI_NAME_1,
       Max(CASE
             WHEN field_id = 2 THEN NON_PI_NAME
             ELSE NULL
           END) AS LL_NON_PI_NAME_2
INTO   #id_ed_fh_pivot_unique
FROM   #id_ed_fh_unique
GROUP  BY title_no,
          PTY_ADDR,
          [Price Paid]

--numbering the rows - leasehold unique
SELECT *,
       DENSE_RANK()
         OVER (
           partition BY title_no
           ORDER BY co_reg_no ) AS field_id
INTO   #id_ed_lh_unique
FROM   #ccoduniqueaddressleasehold

--pivoting - leasehold unique
SELECT title_no,
       PTY_ADDR,
       [Price Paid],
       Max(CASE
             WHEN field_id = 1 THEN CO_REG_NO
             ELSE NULL
           END) AS TT_CO_REG_NO_1,
       Max(CASE
             WHEN field_id = 2 THEN CO_REG_NO
             ELSE NULL
           END) AS TT_CO_REG_NO_2,
       Max(CASE
             WHEN field_id = 1 THEN NON_PI_NAME
             ELSE NULL
           END) AS TT_NON_PI_NAME_1,
       Max(CASE
             WHEN field_id = 2 THEN NON_PI_NAME
             ELSE NULL
           END) AS TT_NON_PI_NAME_2
INTO   #id_ed_lh_pivot_unique
FROM   #id_ed_lh_unique
GROUP  BY title_no,
          PTY_ADDR,
          [Price Paid]

--numbering the rows - freehold non-unique
SELECT *,
       DENSE_RANK()
         OVER (
           partition BY title_no
           ORDER BY co_reg_no ) AS field_id
INTO   #id_ed_fh
FROM   #ccodnonuniqueaddressfreehold

--pivoting - freehold non-unique
SELECT title_no,
       PTY_ADDR,
       [Price Paid],
       Max(CASE
             WHEN field_id = 1 THEN CO_REG_NO
             ELSE NULL
           END) AS LL_CO_REG_NO_1,
       Max(CASE
             WHEN field_id = 2 THEN CO_REG_NO
             ELSE NULL
           END) AS LL_CO_REG_NO_2,
       Max(CASE
             WHEN field_id = 1 THEN NON_PI_NAME
             ELSE NULL
           END) AS LL_NON_PI_NAME_1,
       Max(CASE
             WHEN field_id = 2 THEN NON_PI_NAME
             ELSE NULL
           END) AS LL_NON_PI_NAME_2
INTO   #id_ed_fh_pivot
FROM   #id_ed_fh
GROUP  BY title_no,
          PTY_ADDR,
          [Price Paid]

--numbering the rows - leasehold non-unique
SELECT *,
       DENSE_RANK()
         OVER (
           partition BY title_no
           ORDER BY co_reg_no ) AS field_id
INTO   #id_ed_lh
FROM   #ccodnonuniqueaddressleasehold

--pivoting - leasehold non-unique
SELECT title_no,
       PTY_ADDR,
       [Price Paid],
       Max(CASE
             WHEN field_id = 1 THEN CO_REG_NO
             ELSE NULL
           END) AS TT_CO_REG_NO_1,
       Max(CASE
             WHEN field_id = 2 THEN CO_REG_NO
             ELSE NULL
           END) AS TT_CO_REG_NO_2,
       Max(CASE
             WHEN field_id = 1 THEN NON_PI_NAME
             ELSE NULL
           END) AS TT_NON_PI_NAME_1,
       Max(CASE
             WHEN field_id = 2 THEN NON_PI_NAME
             ELSE NULL
           END) AS TT_NON_PI_NAME_2
INTO   #id_ed_lh_pivot
FROM   #id_ed_lh
GROUP  BY title_no,
          PTY_ADDR,
          [Price Paid]

-- we need to supplement the previous table with the PriceCount -- see more in Step 5
-- this is required for Price matching in Step 8
-- sometimes there are cases where Prices are present in Reg Leases but are all nulls in CCOD for the same address
-- this may result in a situation when we are matching on nulls, Reg Lease NULL will join to multiple CCOD NULLs 
-- we are doing this ONLY FOR LEASEHOLD BECAUSE RegisteredLeasesCurrent ONLY HAS LEASEHOLDS AND NOT FREEHOLDS
SELECT vv.*,
       hh.PriceCount
INTO   #id_ed_lh_pivot_nu_final2
FROM   #id_ed_lh_pivot vv
       LEFT JOIN (SELECT PTY_ADDR,
                         Count([Price Paid]) AS PriceCount
                  FROM   #id_ed_lh_pivot
                  GROUP  BY PTY_ADDR) hh
              ON vv.PTY_ADDR = hh.PTY_ADDR

/* Step 3. Prepare data to later supplement the 1:1 CCOD dataset

in CCOD there are addresses that are assoc w more than 1 leashold (or freehold) title number
but actually it is the same company that holds these titles. We are going to be working with company names,
since co_reg_no_s are not reliable. For example,
same company may display their co_reg_no 2576 and on the next line - 00002576, i.e. co_reg_nos require editing, so for now
I will focus on names (NON_PI_NAME), since it gives us more matches.*/
/*Select those addresses, for which there is more than 1 title number but only 1 NON_PI_NAME_1 per address

In order to avoid duplicates, I replace the values of the columns  title_no, co_reg_nos, price and second leaseholder for NULLs
this is because I will need to select "distinct" and if these columns have varying values, there will be duplicates in terms of the company names.
This way some information is lost, but the goal of this exercise is to establish the company, so that what we focus on.
Because I will be doing union all , I need to specify the var types for the NULLs
*/
-- for leasehold
SELECT DISTINCT *
INTO   #oneleaseholder
FROM   (SELECT Cast(NULL AS VARCHAR(9))   AS Title_no,
               ee.pty_addr,
               NULL                       AS [Price Paid],
               Cast(NULL AS VARCHAR(50))  AS TT_CO_REG_NO_1,
               Cast(NULL AS VARCHAR(50))  AS TT_CO_REG_NO_2,
               ee.TT_NON_PI_NAME_1,
               Cast(NULL AS VARCHAR(500)) AS TT_NON_PI_NAME_2
        FROM   #id_ed_lh_pivot ee
               INNER JOIN (SELECT pty_addr
                           FROM   #id_ed_lh_pivot
                           GROUP  BY pty_addr
                           HAVING Count(title_no) > 1
                                  AND Count(DISTINCT tt_non_pi_name_1) = 1) ll
                       ON ee.pty_addr = ll.pty_addr) oo
ORDER  BY oo.pty_addr

--for freehold
SELECT DISTINCT *
INTO   #onefreeholder
FROM   (SELECT Cast(NULL AS VARCHAR(9))   AS Title_no,
               ee.pty_addr,
               NULL                       AS [Price Paid],
               Cast(NULL AS VARCHAR(50))  AS LL_CO_REG_NO_1,
               Cast(NULL AS VARCHAR(50))  AS LL_CO_REG_NO_2,
               ee.LL_NON_PI_NAME_1,
               Cast(NULL AS VARCHAR(500)) AS LL_NON_PI_NAME_2
        FROM   #id_ed_fh_pivot ee
               INNER JOIN (SELECT pty_addr
                           FROM   #id_ed_fh_pivot
                           GROUP  BY pty_addr
                           HAVING Count(title_no) > 1
                                  AND Count(DISTINCT ll_non_pi_name_1) = 1) ll
                       ON ee.pty_addr = ll.pty_addr) oo
ORDER  BY oo.pty_addr

/*** Step 4. Diving the Registered Leases table into 2 parts:
 1 address - 1 lease and 1 address - multiple leases ***/
-- 1:1 sample
SELECT DISTINCT registerpropertydescription
INTO   #single
FROM   (SELECT registerpropertydescription
        FROM   [LandReg].[dbo].[registeredleasescurrent]
        GROUP  BY registerpropertydescription
        HAVING Count(DISTINCT UniqueIdentifier) = 1) zz

-- 1:m sample
SELECT kk.*
INTO   #multiple
FROM   (SELECT registerpropertydescription
        FROM   [LandReg].[dbo].[registeredleasescurrent]
        GROUP  BY registerpropertydescription
        HAVING Count(DISTINCT UniqueIdentifier) > 1) kk

/*** Step 5. Selecting the addresses where the match can be done on PricePaid

Another way to supplement the 1:1 sample is to match on PricePaid.
This is not always possible. The rules for the correct join are as follows:

- The address has to have 1 or more unique PricePaid 
   - if PricePaid is not unique, there will be a duplicate match, that is why I am grouping by Price and counting the number of lease ids
- The address may have up to 1 NULL price max, which can be matched on, but if and only if the address has other non-null prices
- if the address has more than 1 NULL, the match is not done on non-NULL prices
- we must make sure that when matching on NULLs, on CCOD side, not all observations are NULLs, because otherwise we'll get duplicates
 ***/
-- selecting addresses from #multiple sample , where prices don't repeat
SELECT DISTINCT registerpropertydescription
INTO   #nonrepprices
FROM   (SELECT DISTINCT UniqueIdentifier,
                        a.RegisterPropertyDescription,
                        PricePaid
        FROM   [LandReg].[dbo].[registeredleasescurrent] a
               INNER JOIN #multiple b
                       ON a.registerpropertydescription =
                          b.registerpropertydescription
        WHERE  a.registerpropertydescription <>
               'Unavailable - refer to Associated Property Description') c
GROUP  BY registerpropertydescription,
          PricePaid
HAVING Count(UniqueIdentifier) = 1
ORDER  BY registerpropertydescription

--- out of the above, select those that have only 1 null
SELECT DISTINCT registerpropertydescription
INTO   #nonrep1null
FROM   (SELECT DISTINCT UniqueIdentifier,
                        ii.RegisterPropertyDescription,
                        PricePaid
        FROM   [LandReg].[dbo].[registeredleasescurrent] ii
               INNER JOIN #nonrepprices vv
                       ON ii.registerpropertydescription =
                          vv.registerpropertydescription) c
GROUP  BY registerpropertydescription
HAVING Sum(CASE
             WHEN PricePaid IS NULL THEN 1
             ELSE 0
           END) <= 1
ORDER  BY registerpropertydescription

--- add the outcome of the last table as a boolean variable (oneorlessnulls) to the original set of addresses #nonrepprices
SELECT kk.*,
       CASE
         WHEN ee.RegisterPropertyDescription IS NOT NULL THEN 1
         ELSE 0
       END AS oneorlessnulls
INTO   #matchingnrpice
FROM   #nonrepprices kk
       LEFT JOIN #nonrep1null ee
              ON kk.RegisterPropertyDescription = ee.RegisterPropertyDescription

/*** Step 6. Working with the outcome of the fuzzy matching to supplement the missing UPRNs ***/
--First, we need to identify the duplicates with 100 score matches from Fuzzy matching table  
SELECT [AssociatedPropertyDescription ID]
INTO   #dupl
FROM   (SELECT *
        FROM   [LandReg].[dbo].[registeredleases_addressbasefmfw]
        WHERE  Matchscore = 100
               AND Leases_Address = [AddressBase_Address]) i
GROUP  BY [AssociatedPropertyDescription ID]
HAVING Count([AssociatedPropertyDescription ID]) > 1

-- then remove the duplicates
SELECT i.*
INTO   #unique
FROM   (SELECT *
        FROM   [LandReg].[dbo].[registeredleases_addressbasefmfw]
        WHERE  Matchscore = 100
               AND Leases_Address = [AddressBase_Address]) i
       LEFT JOIN #dupl p
              ON i.[AssociatedPropertyDescription ID] =
                 p.[AssociatedPropertyDescription ID]
WHERE  p.[AssociatedPropertyDescription ID] IS NULL

-- Supplementing missing UPRNs with Fuzzy Match unique 100 match score results
SELECT j.TableID,
       j.UniqueIdentifier,
       j.RegisterPropertyDescription,
       j.[RegisterPropertyDescription_Postcode],
       j.[AssociatedPropertyDescription ID],
       j.County,
       j.AssociatedPropertyDescription,
       j.[AssociatedPropertyDescription_Postcode],
       CASE
         WHEN OSUPRN IS NULL
              AND UPRN IS NOT NULL THEN uprn
         ELSE OSUPRN
       END AS OSUPRN,
       PricePaid,
       Term,
       LeaseStart,
       LeaseEnd,
       Years,
       StartDate
INTO   #suppluprn
FROM   [LandReg].[dbo].[registeredleasescurrent] j
       LEFT JOIN #unique z
              ON j.[AssociatedPropertyDescription ID] =
                 z.[AssociatedPropertyDescription ID]

/*** Step 7. Adding property class to leases ***/
SELECT DISTINCT TableID,
                UniqueIdentifier,
                RegisterPropertyDescription,
                [RegisterPropertyDescription_Postcode],
                [AssociatedPropertyDescription ID],
                f.County,
                AssociatedPropertyDescription,
                [AssociatedPropertyDescription_Postcode],
                OSUPRN,
                PricePaid,
                Term,
                LeaseStart,
                LeaseEnd,
                Years,
                StartDate,
                e.class           AS class_code,
                b.class_desc,
                b.primary_desc,
                b.secondary_desc,
                b.tertiary_desc,
                e.voa_ndr_record,
                y.[PrimaryDescNM] AS PrimaryDescVOA
INTO   #step3
FROM   #suppluprn f --attach property type where available  
       LEFT JOIN (SELECT *
                  FROM   [GeoData].[dbo].osaddressbaseplus_master
                  WHERE  UPRN IS NOT NULL) e
              ON f.osuprn = e.UPRN
       /*property class*/
       LEFT JOIN [GeoData].[dbo].[osaddressbaseplus_classlkup] b
              ON e.class = b.concatenated
       LEFT JOIN [VOARating].[dbo].[ratinglistentriescurrent] y
              ON e.voa_ndr_record = y.UARN

/*** Step 8. MATCHING ON PRICE IN A NON-UNIQUE LEASES SAMPLE (MATRIX) 

-- we are  going to remove the part of the observations that matched on price

-- WHERE clause reflects the conditions for matching we previously outlined in Step 5:
--      - the exact match on price if and only if address belongs to the sample of addresses with non-repeating prices (#matchingnrpice)
        - match on NULL if and only if there's only 1 NULL and on CCOD side Price Count is more than 0

***/
SELECT TableID,
       UniqueIdentifier,
       u.RegisterPropertyDescription,
       RegisterPropertyDescription_Postcode,
       u.County,
       [AssociatedPropertyDescription ID],
       AssociatedPropertyDescription,
       AssociatedPropertyDescription_Postcode,
       OSUPRN                      AS UPRN,
       PricePaid,
       Term,
       LeaseStart,
       LeaseEnd,
       Years,
       StartDate,
       Class_Code,
       Class_Desc,
       Primary_Desc,
       Secondary_Desc,
       Tertiary_Desc,
       VOA_NDR_RECORD,
       PrimaryDescVOA,
       b.title_no                  AS Title_no_freehold_domestic,
       ll_co_reg_no_1              AS CO_REG_NO_Freeholder_domestic_1,
       ll_non_pi_name_1            AS Freeholder_domestic_1,
       ll_co_reg_no_2              AS CO_REG_NO_Freeholder_domestic_2,
       ll_non_pi_name_2            AS Freeholder_domestic_2,
       j.title_number              AS Title_no_freehold_overseas,
       j.company_registration_no_1 AS CO_REG_NO_Freeholder_overseas_1,
       j.proprietor_name_1         AS Freeholder_overseas_1,
       j.company_registration_no_2 AS CO_REG_NO_Freeholder_overseas_2,
       j.proprietor_name_2         AS Freeholder_overseas_2,
       j.Company_Registration_No_3 AS CO_REG_NO_Freeholder_overseas_3,
       j.proprietor_name_3         AS Freeholder_overseas_3,
       j.company_registration_no_4 AS CO_REG_NO_Freeholder_overseas_4,
       j.proprietor_name_4         AS Freeholder_overseas_4,
       w.title_no                  AS Title_no_leasehold_domestic,
       tt_co_reg_no_1              AS CO_REG_NO_Leaseholder_domestic_1,
       tt_non_pi_name_1            AS Leaseholder_domestic_1,
       tt_co_reg_no_2              AS CO_REG_NO_Leaseholder_domestic_2,
       tt_non_pi_name_2            AS Leaseholder_domestic_2,
       p.title_number              AS Title_no_leasehold_overseas,
       p.company_registration_no_1 AS CO_REG_NO_Leaseholder_overseas_1,
       p.proprietor_name_1         AS Leaseholder_overseas_1,
       p.company_registration_no_2 AS CO_REG_NO_Leaseholder_overseas_2,
       p.proprietor_name_2         AS Leaseholder_overseas_2,
       p.company_registration_no_3 AS CO_REG_NO_Leaseholder_overseas_3,
       p.proprietor_name_3         AS Leaseholder_overseas_3,
       p.company_registration_no_4 AS CO_REG_NO_Leaseholder_overseas_4,
       p.proprietor_name_4         AS Leaseholder_overseas_4,
       Getdate()                   AS UpdateDate
INTO   #add_to_single
FROM   (SELECT d.*
        FROM   #step3 d
               INNER JOIN #multiple f
                       ON d.registerpropertydescription =
                          f.registerpropertydescription
       ) u
       LEFT JOIN #id_ed_lh_pivot_nu_final2 w
              ON u.registerpropertydescription = w.pty_addr
       LEFT JOIN #id_ed_fh_pivot b
              ON u.registerpropertydescription = b.pty_addr
       LEFT JOIN (SELECT *
                  FROM   [LandReg].[dbo].[overseascompanies]
                  WHERE  tenure = 'leasehold') p
              ON u.registerpropertydescription = p.property_address
       LEFT JOIN (SELECT *
                  FROM   [LandReg].[dbo].[overseascompanies]
                  WHERE  tenure = 'freehold') j
              ON u.registerpropertydescription = j.property_address
       LEFT JOIN #matchingnrpice mp
              ON u.registerpropertydescription = mp.RegisterPropertyDescription
WHERE  ( b.title_no IS NOT NULL
          OR w.title_no IS NOT NULL
          OR p.title_number IS NOT NULL
          OR j.title_number IS NOT NULL )
       AND ( ( u.PricePaid = w.[Price Paid]
               AND mp.RegisterPropertyDescription IS NOT NULL )
              OR ( w.[Price Paid] IS NULL
                   AND u.PricePaid IS NULL
                   AND mp.oneorlessnulls = 1
                   AND w.PriceCount > 0 ) )

--- remove addresses of #add_to_single from oneleaseholder table IN ORDER TO AVOID DOUBLE COUNTING OF
--- SUCH ADDRESSES IN BOTH add_to_single AND #oneleaseholder TABLES
SELECT g.*
INTO   #oneleaseholder2
FROM   #oneleaseholder g
       LEFT JOIN (SELECT DISTINCT RegisterPropertyDescription
                  FROM   #add_to_single)m
              ON g.PTY_ADDR = m.RegisterPropertyDescription
WHERE  m.RegisterPropertyDescription IS NULL

/*** Step 9. NON-UNIQUE LEASES SAMPLE (MATRIX) ***/
-- now finally, the remaining unidentified sample
-- WHERE clause is rather complex but reflects the cases when
-- prices are just unequal
-- equal but this address has other leases with the same price 
-- one of the Prices is NULL (NULLs don't participate in = and <> logical operator
-- both prices are NULL , but either this is the address with more than 1 NULL or the address with more than 1 unique price or on CCOD side there are no prices
SELECT TableID,
       UniqueIdentifier,
       u.RegisterPropertyDescription,
       RegisterPropertyDescription_Postcode,
       u.County,
       [AssociatedPropertyDescription ID],
       AssociatedPropertyDescription,
       AssociatedPropertyDescription_Postcode,
       OSUPRN                      AS UPRN,
       PricePaid,
       Term,
       LeaseStart,
       LeaseEnd,
       Years,
       StartDate,
       Class_Code,
       Class_Desc,
       Primary_Desc,
       Secondary_Desc,
       Tertiary_Desc,
       VOA_NDR_RECORD,
       PrimaryDescVOA,
       b.title_no                  AS Title_no_freehold_domestic,
       ll_co_reg_no_1              AS CO_REG_NO_Freeholder_domestic_1,
       ll_non_pi_name_1            AS Freeholder_domestic_1,
       ll_co_reg_no_2              AS CO_REG_NO_Freeholder_domestic_2,
       ll_non_pi_name_2            AS Freeholder_domestic_2,
       j.title_number              AS Title_no_freehold_overseas,
       j.company_registration_no_1 AS CO_REG_NO_Freeholder_overseas_1,
       j.proprietor_name_1         AS Freeholder_overseas_1,
       j.company_registration_no_2 AS CO_REG_NO_Freeholder_overseas_2,
       j.proprietor_name_2         AS Freeholder_overseas_2,
       j.Company_Registration_No_3 AS CO_REG_NO_Freeholder_overseas_3,
       j.proprietor_name_3         AS Freeholder_overseas_3,
       j.company_registration_no_4 AS CO_REG_NO_Freeholder_overseas_4,
       j.proprietor_name_4         AS Freeholder_overseas_4,
       w.title_no                  AS Title_no_leasehold_domestic,
       tt_co_reg_no_1              AS CO_REG_NO_Leaseholder_domestic_1,
       tt_non_pi_name_1            AS Leaseholder_domestic_1,
       tt_co_reg_no_2              AS CO_REG_NO_Leaseholder_domestic_2,
       tt_non_pi_name_2            AS Leaseholder_domestic_2,
       p.title_number              AS Title_no_leasehold_overseas,
       p.company_registration_no_1 AS CO_REG_NO_Leaseholder_overseas_1,
       p.proprietor_name_1         AS Leaseholder_overseas_1,
       p.company_registration_no_2 AS CO_REG_NO_Leaseholder_overseas_2,
       p.proprietor_name_2         AS Leaseholder_overseas_2,
       p.company_registration_no_3 AS CO_REG_NO_Leaseholder_overseas_3,
       p.proprietor_name_3         AS Leaseholder_overseas_3,
       p.company_registration_no_4 AS CO_REG_NO_Leaseholder_overseas_4,
       p.proprietor_name_4         AS Leaseholder_overseas_4,
       Getdate()                   AS UpdateDate
INTO   #final_multiple
FROM   (SELECT d.*
        FROM   #step3 d
               INNER JOIN #multiple f
                       ON d.registerpropertydescription =
                          f.registerpropertydescription
       ) u
       LEFT JOIN #id_ed_lh_pivot_nu_final2 w
              ON u.registerpropertydescription = w.pty_addr
       LEFT JOIN #id_ed_fh_pivot b
              ON u.registerpropertydescription = b.pty_addr
       LEFT JOIN (SELECT *
                  FROM   [LandReg].[dbo].[overseascompanies]
                  WHERE  tenure = 'leasehold') p
              ON u.registerpropertydescription = p.property_address
       LEFT JOIN (SELECT *
                  FROM   [LandReg].[dbo].[overseascompanies]
                  WHERE  tenure = 'freehold') j
              ON u.registerpropertydescription = j.property_address
       LEFT JOIN #matchingnrpice mp
              ON u.registerpropertydescription = mp.RegisterPropertyDescription
WHERE  ( b.title_no IS NOT NULL
          OR w.title_no IS NOT NULL
          OR p.title_number IS NOT NULL
          OR j.title_number IS NOT NULL )
       AND ( u.PricePaid <> w.[Price Paid]
              OR ( u.PricePaid = w.[Price Paid]
                   AND mp.RegisterPropertyDescription IS NULL )
              OR ( u.PricePaid IS NOT NULL
                   AND w.[Price Paid] IS NULL )
              OR ( u.PricePaid IS NULL
                   AND w.[Price Paid] IS NOT NULL )
              OR ( ( u.PricePaid IS NULL
                     AND w.[Price Paid] IS NULL )
                   AND ( mp.oneorlessnulls = 0
                          OR mp.oneorlessnulls IS NULL
                          OR w.PriceCount IS NULL
                          OR w.PriceCount = 0 ) ) )

-- a sample of leases where we do not know title numbers but know either freeholder or leaseholder name (See Step 3)  
-- since this will be added to the unique leases, I am removing the overseas columns since we don't know to which title did it belong
SELECT DISTINCT *
INTO   #onename
FROM   (SELECT TableID,
               UniqueIdentifier,
               RegisterPropertyDescription,
               RegisterPropertyDescription_Postcode,
               County,
               [AssociatedPropertyDescription ID],
               AssociatedPropertyDescription,
               AssociatedPropertyDescription_Postcode,
               UPRN,
               PricePaid,
               Term,
               LeaseStart,
               LeaseEnd,
               Years,
               StartDate,
               Class_code,
               Class_desc,
               Primary_Desc,
               Secondary_Desc,
               Tertiary_Desc,
               VOA_NDR_RECORD,
               PrimaryDescVOA,
               Cast(NULL AS VARCHAR(9))   AS Title_no_leasehold_domestic,
               Cast(NULL AS VARCHAR(50))  AS CO_REG_NO_leaseholder_domestic_1,
               c.TT_NON_PI_NAME_1         AS Leaseholder_domestic_1,
               Cast(NULL AS VARCHAR(50))  AS CO_REG_NO_leaseholder_domestic_2,
               Cast(NULL AS VARCHAR(500)) AS Leaseholder_domestic_2,
               Cast(NULL AS VARCHAR(9))   AS Title_no_leasehold_overseas,
               Cast(NULL AS VARCHAR(50))  AS CO_REG_NO_leaseholder_overseas_1,
               Cast(NULL AS VARCHAR(500)) AS Leaseholder_overseas_1,
               Cast(NULL AS VARCHAR(50))  AS CO_REG_NO_leaseholder_overseas_2,
               Cast(NULL AS VARCHAR(500)) AS Leaseholder_overseas_2,
               Cast(NULL AS VARCHAR(50))  AS CO_REG_NO_leaseholder_overseas_3,
               Cast(NULL AS VARCHAR(500)) AS Leaseholder_overseas_3,
               Cast(NULL AS VARCHAR(50))  AS CO_REG_NO_leaseholder_overseas_4,
               Cast(NULL AS VARCHAR(500)) AS Leaseholder_overseas_4,
               Cast(NULL AS VARCHAR(9))   AS Title_no_freehold_domestic,
               Cast(NULL AS VARCHAR(50))  AS CO_REG_NO_Freeholder_domestic_1,
               y.LL_NON_PI_NAME_1         AS Freeholder_domestic_1,
               Cast(NULL AS VARCHAR(50))  AS CO_REG_NO_Freeholder_domestic_2,
               Cast(NULL AS VARCHAR(500)) AS Freeholder_domestic_2,
               Cast(NULL AS VARCHAR(9))   AS Title_no_freehold_overseas,
               Cast(NULL AS VARCHAR(50))  AS CO_REG_NO_Freeholder_overseas_1,
               Cast(NULL AS VARCHAR(500)) AS Freeholder_overseas_1,
               Cast(NULL AS VARCHAR(50))  AS CO_REG_NO_Freeholder_overseas_2,
               Cast(NULL AS VARCHAR(500)) AS Freeholder_overseas_2,
               Cast(NULL AS VARCHAR(50))  AS CO_REG_NO_Freeholder_overseas_3,
               Cast(NULL AS VARCHAR(500)) AS Freeholder_overseas_3,
               Cast(NULL AS VARCHAR(50))  AS CO_REG_NO_Freeholder_overseas_4,
               Cast(NULL AS VARCHAR(500)) AS Freeholder_overseas_4,
               UpdateDate
        FROM   #final_multiple k
               LEFT JOIN #onefreeholder y
                      ON k.RegisterPropertyDescription = y.PTY_ADDR
               LEFT JOIN #oneleaseholder2 c
                      ON k.RegisterPropertyDescription = c.PTY_ADDR
        WHERE  y.PTY_ADDR IS NOT NULL
                OR c.PTY_ADDR IS NOT NULL)m

-- remove #onefreeholder addresses from #final_multiple
SELECT k.*
INTO   #final_multiple2
FROM   #final_multiple k
       LEFT JOIN #onefreeholder y
              ON k.RegisterPropertyDescription = y.PTY_ADDR
WHERE  y.PTY_ADDR IS NULL

--- further remove ##oneleaseholder addresses from #final_multiple
-- had to do in two steps since in one query it took too long
SELECT v.*
INTO   #final_multiple3
FROM   #final_multiple2 v
       LEFT JOIN #oneleaseholder c
              ON v.RegisterPropertyDescription = c.PTY_ADDR
WHERE  c.PTY_ADDR IS NULL

/*** Step 10. Reuploading the table - NON-UNIQUE LEASE MATRIX ***/
DROP TABLE [LandReg].[dbo].[ccodleasesunidentifiedmatrix]

CREATE TABLE [LandReg].[dbo].[ccodleasesunidentifiedmatrix]
  (
     TableID                                INT,
     UniqueIdentifier                       CHAR(40),
     RegisterPropertyDescription            VARCHAR(1000),
     RegisterPropertyDescription_Postcode   VARCHAR(10),
     County                                 VARCHAR(40),
     [AssociatedPropertyDescription ID]     BIGINT,
     AssociatedPropertyDescription          VARCHAR(255),
     AssociatedPropertyDescription_Postcode VARCHAR(10),
     ADDR_ID                                VARCHAR(100),
     UPRN                                   BIGINT,
     PricePaid                              MONEY,
     Term                                   VARCHAR(400),
     LeaseStart                             DATE,
     LeaseEnd                               DATE,
     Years                                  INT,
     StartDate                              DATE,
     Class_code                             VARCHAR(6),
     Class_desc                             VARCHAR(255),
     Primary_Desc                           VARCHAR(255),
     Secondary_Desc                         VARCHAR(255),
     Tertiary_Desc                          VARCHAR(255),
     VOA_NDR_RECORD                         BIGINT,
     PrimaryDescVOA                         VARCHAR(60),
     Title_no_leasehold_domestic            VARCHAR(9),
     CO_REG_NO_leaseholder_domestic_1       VARCHAR(50),
     Leaseholder_domestic_1                 VARCHAR(500),
     CO_REG_NO_leaseholder_domestic_2       VARCHAR(50),
     Leaseholder_domestic_2                 VARCHAR(500),
     Title_no_leasehold_overseas            VARCHAR(9),
     CO_REG_NO_leaseholder_overseas_1       VARCHAR(50),
     Leaseholder_overseas_1                 VARCHAR(500),
     CO_REG_NO_leaseholder_overseas_2       VARCHAR(50),
     Leaseholder_overseas_2                 VARCHAR(500),
     CO_REG_NO_leaseholder_overseas_3       VARCHAR(50),
     Leaseholder_overseas_3                 VARCHAR(500),
     CO_REG_NO_leaseholder_overseas_4       VARCHAR(50),
     Leaseholder_overseas_4                 VARCHAR(500),
     Title_no_freehold_domestic             VARCHAR(9),
     CO_REG_NO_Freeholder_domestic_1        VARCHAR(50),
     Freeholder_domestic_1                  VARCHAR(500),
     CO_REG_NO_Freeholder_domestic_2        VARCHAR(50),
     Freeholder_domestic_2                  VARCHAR(500),
     Title_no_freehold_overseas             VARCHAR(9),
     CO_REG_NO_Freeholder_overseas_1        VARCHAR(50),
     Freeholder_overseas_1                  VARCHAR(500),
     CO_REG_NO_Freeholder_overseas_2        VARCHAR(50),
     Freeholder_overseas_2                  VARCHAR(500),
     CO_REG_NO_Freeholder_overseas_3        VARCHAR(50),
     Freeholder_overseas_3                  VARCHAR(500),
     CO_REG_NO_Freeholder_overseas_4        VARCHAR(50),
     Freeholder_overseas_4                  VARCHAR(500),
     UpdateDate                             DATETIME
  )

TRUNCATE TABLE [LandReg].[dbo].[ccodleasesunidentifiedmatrix];

INSERT INTO [LandReg].[dbo].[ccodleasesunidentifiedmatrix]
            (TableID,
             UniqueIdentifier,
             RegisterPropertyDescription,
             RegisterPropertyDescription_Postcode,
             County,
             [AssociatedPropertyDescription ID],
             AssociatedPropertyDescription,
             AssociatedPropertyDescription_Postcode,
             UPRN,
             PricePaid,
             Term,
             LeaseStart,
             LeaseEnd,
             Years,
             StartDate,
             Class_code,
             Class_desc,
             Primary_Desc,
             Secondary_Desc,
             Tertiary_Desc,
             VOA_NDR_RECORD,
             PrimaryDescVOA,
             Title_no_leasehold_domestic,
             CO_REG_NO_leaseholder_domestic_1,
             Leaseholder_domestic_1,
             CO_REG_NO_leaseholder_domestic_2,
             Leaseholder_domestic_2,
             Title_no_leasehold_overseas,
             CO_REG_NO_leaseholder_overseas_1,
             Leaseholder_overseas_1,
             CO_REG_NO_leaseholder_overseas_2,
             Leaseholder_overseas_2,
             CO_REG_NO_leaseholder_overseas_3,
             Leaseholder_overseas_3,
             CO_REG_NO_leaseholder_overseas_4,
             Leaseholder_overseas_4,
             Title_no_freehold_domestic,
             CO_REG_NO_Freeholder_domestic_1,
             Freeholder_domestic_1,
             CO_REG_NO_Freeholder_domestic_2,
             Freeholder_domestic_2,
             Title_no_freehold_overseas,
             CO_REG_NO_Freeholder_overseas_1,
             Freeholder_overseas_1,
             CO_REG_NO_Freeholder_overseas_2,
             Freeholder_overseas_2,
             CO_REG_NO_Freeholder_overseas_3,
             Freeholder_overseas_3,
             CO_REG_NO_Freeholder_overseas_4,
             Freeholder_overseas_4,
             UpdateDate)
(SELECT TableID,
        UniqueIdentifier,
        RegisterPropertyDescription,
        RegisterPropertyDescription_Postcode,
        County,
        [AssociatedPropertyDescription ID],
        AssociatedPropertyDescription,
        AssociatedPropertyDescription_Postcode,
        UPRN,
        PricePaid,
        Term,
        LeaseStart,
        LeaseEnd,
        Years,
        StartDate,
        Class_code,
        Class_desc,
        Primary_Desc,
        Secondary_Desc,
        Tertiary_Desc,
        VOA_NDR_RECORD,
        PrimaryDescVOA,
        Title_no_leasehold_domestic,
        CO_REG_NO_leaseholder_domestic_1,
        Leaseholder_domestic_1,
        CO_REG_NO_leaseholder_domestic_2,
        Leaseholder_domestic_2,
        Title_no_leasehold_overseas,
        CO_REG_NO_leaseholder_overseas_1,
        Leaseholder_overseas_1,
        CO_REG_NO_leaseholder_overseas_2,
        Leaseholder_overseas_2,
        CO_REG_NO_leaseholder_overseas_3,
        Leaseholder_overseas_3,
        CO_REG_NO_leaseholder_overseas_4,
        Leaseholder_overseas_4,
        Title_no_freehold_domestic,
        CO_REG_NO_Freeholder_domestic_1,
        Freeholder_domestic_1,
        CO_REG_NO_Freeholder_domestic_2,
        Freeholder_domestic_2,
        Title_no_freehold_overseas,
        CO_REG_NO_Freeholder_overseas_1,
        Freeholder_overseas_1,
        CO_REG_NO_Freeholder_overseas_2,
        Freeholder_overseas_2,
        CO_REG_NO_Freeholder_overseas_3,
        Freeholder_overseas_3,
        CO_REG_NO_Freeholder_overseas_4,
        Freeholder_overseas_4,
        UpdateDate
 FROM   #final_multiple3)

/*** Step 11. UNIQUE LEASES SAMPLE ***/
SELECT TableID,
       UniqueIdentifier,
       RegisterPropertyDescription,
       RegisterPropertyDescription_Postcode,
       u.County,
       [AssociatedPropertyDescription ID],
       AssociatedPropertyDescription,
       AssociatedPropertyDescription_Postcode,
       OSUPRN                      AS UPRN,
       PricePaid,
       Term,
       LeaseStart,
       LeaseEnd,
       Years,
       StartDate,
       Class_Code,
       Class_Desc,
       Primary_Desc,
       Secondary_Desc,
       Tertiary_Desc,
       VOA_NDR_RECORD,
       PrimaryDescVOA,
       b.title_no                  AS Title_no_freehold_domestic,
       ll_co_reg_no_1              AS CO_REG_NO_Freeholder_domestic_1,
       ll_non_pi_name_1            AS Freeholder_domestic_1,
       ll_co_reg_no_2              AS CO_REG_NO_Freeholder_domestic_2,
       ll_non_pi_name_2            AS Freeholder_domestic_2,
       j.title_number              AS Title_no_freehold_overseas,
       j.company_registration_no_1 AS CO_REG_NO_Freeholder_overseas_1,
       j.proprietor_name_1         AS Freeholder_overseas_1,
       j.company_registration_no_2 AS CO_REG_NO_Freeholder_overseas_2,
       j.proprietor_name_2         AS Freeholder_overseas_2,
       j.Company_Registration_No_3 AS CO_REG_NO_Freeholder_overseas_3,
       j.proprietor_name_3         AS Freeholder_overseas_3,
       j.company_registration_no_4 AS CO_REG_NO_Freeholder_overseas_4,
       j.proprietor_name_4         AS Freeholder_overseas_4,
       w.title_no                  AS Title_no_leasehold_domestic,
       tt_co_reg_no_1              AS CO_REG_NO_Leaseholder_domestic_1,
       tt_non_pi_name_1            AS Leaseholder_domestic_1,
       tt_co_reg_no_2              AS CO_REG_NO_Leaseholder_domestic_2,
       tt_non_pi_name_2            AS Leaseholder_domestic_2,
       p.title_number              AS Title_no_leasehold_overseas,
       p.company_registration_no_1 AS CO_REG_NO_Leaseholder_overseas_1,
       p.proprietor_name_1         AS Leaseholder_overseas_1,
       p.company_registration_no_2 AS CO_REG_NO_Leaseholder_overseas_2,
       p.proprietor_name_2         AS Leaseholder_overseas_2,
       p.company_registration_no_3 AS CO_REG_NO_Leaseholder_overseas_3,
       p.proprietor_name_3         AS Leaseholder_overseas_3,
       p.company_registration_no_4 AS CO_REG_NO_Leaseholder_overseas_4,
       p.proprietor_name_4         AS Leaseholder_overseas_4,
       Getdate()                   AS UpdateDate
INTO   #final
FROM   (SELECT d.*
        FROM   #step3 d
               INNER JOIN #single f
                       ON d.registerpropertydescription =
                          f.registerpropertydescription
       ) u
       LEFT JOIN #id_ed_lh_pivot_unique w
              ON u.registerpropertydescription = w.pty_addr
       LEFT JOIN #id_ed_fh_pivot_unique b
              ON u.registerpropertydescription = b.pty_addr
       LEFT JOIN (SELECT *
                  FROM   [LandReg].[dbo].[overseascompanies]
                  WHERE  tenure = 'leasehold') p
              ON u.registerpropertydescription = p.property_address
       LEFT JOIN (SELECT *
                  FROM   [LandReg].[dbo].[overseascompanies]
                  WHERE  tenure = 'freehold') j
              ON u.registerpropertydescription = j.property_address
WHERE  b.title_no IS NOT NULL
        OR b.ll_non_pi_name_1 IS NOT NULL
        OR w.title_no IS NOT NULL
        OR w.tt_non_pi_name_1 IS NOT NULL
        OR p.title_number IS NOT NULL
        OR j.title_number IS NOT NULL

--EXEC [tempdb].[dbo].[sp_help] N'#final'
/*** Step 12. Updating the table with generalised Primary_desc - if UPRN is missing we can't get the property class
one postocde can be associated with multiple UPRNs
the idea is, if UPRN is missing, take the postcode, find all the UPRNs that are assoc with it,
check their Primary Desc, if all the Primary Descs are the same, apply this Primary Desc to the postocde
 ***/
-- selecting the postocde with missing UPRNs and fetching their corresponding primary_descs
-- don't forget to add the rows matched on price
SELECT DISTINCT w.primary_desc,
                j.RegisterPropertyDescription_Postcode
INTO   #selection
FROM   (
       -- select postocodes where uprn is null
       SELECT DISTINCT registerpropertydescription_postcode
        FROM   (SELECT *
                FROM   #final
                UNION ALL
                SELECT DISTINCT *
                FROM   #add_to_single
                UNION ALL
                SELECT *
                FROM   #onename) oo
        WHERE  uprn IS NULL) j
       -- join to address base tables to get class
       INNER JOIN [GeoData].[dbo].[osaddressbaseplus_master] q
               ON j.RegisterPropertyDescription_Postcode = q.POSTCODE_LOCATOR
       INNER JOIN [GeoData].[dbo].[osaddressbaseplus_classlkup] w
               ON q.class = w.concatenated
WHERE  w.Primary_Desc NOT LIKE '%Parent%'

-- take only those postcodes which have only one Primary_desc type
SELECT RegisterPropertyDescription_Postcode
INTO   #uniquepropdescr_postcodes
FROM   #selection e
GROUP  BY RegisterPropertyDescription_Postcode
HAVING Count(primary_desc) = 1

-- attach it back to the original sample #selection
SELECT k.*
INTO   #uniquepropdescr
FROM   #selection k
       INNER JOIN #uniquepropdescr_postcodes d
               ON k.RegisterPropertyDescription_Postcode =
                  d.RegisterPropertyDescription_Postcode

-- replace the Primary_desc where applicable 
SELECT TableID,
       UniqueIdentifier,
       RegisterPropertyDescription,
       t.RegisterPropertyDescription_Postcode,
       County,
       [AssociatedPropertyDescription ID],
       AssociatedPropertyDescription,
       AssociatedPropertyDescription_Postcode,
       UPRN,
       PricePaid,
       Term,
       LeaseStart,
       LeaseEnd,
       Years,
       StartDate,
       Class_code,
       Class_desc,
       CASE
         WHEN t.Primary_Desc IS NULL
              AND r.Primary_Desc IS NOT NULL THEN r.Primary_Desc
         ELSE t.Primary_Desc
       END AS Primary_Desc,
       Secondary_Desc,
       Tertiary_Desc,
       VOA_NDR_RECORD,
       PrimaryDescVOA,
       Title_no_leasehold_domestic,
       CO_REG_NO_leaseholder_domestic_1,
       Leaseholder_domestic_1,
       CO_REG_NO_leaseholder_domestic_2,
       Leaseholder_domestic_2,
       Title_no_leasehold_overseas,
       CO_REG_NO_leaseholder_overseas_1,
       Leaseholder_overseas_1,
       CO_REG_NO_leaseholder_overseas_2,
       Leaseholder_overseas_2,
       CO_REG_NO_leaseholder_overseas_3,
       Leaseholder_overseas_3,
       CO_REG_NO_leaseholder_overseas_4,
       Leaseholder_overseas_4,
       Title_no_freehold_domestic,
       CO_REG_NO_Freeholder_domestic_1,
       Freeholder_domestic_1,
       CO_REG_NO_Freeholder_domestic_2,
       Freeholder_domestic_2,
       Title_no_freehold_overseas,
       CO_REG_NO_Freeholder_overseas_1,
       Freeholder_overseas_1,
       CO_REG_NO_Freeholder_overseas_2,
       Freeholder_overseas_2,
       CO_REG_NO_Freeholder_overseas_3,
       Freeholder_overseas_3,
       CO_REG_NO_Freeholder_overseas_4,
       Freeholder_overseas_4,
       UpdateDate
INTO   #final_updated
FROM   (SELECT *
        FROM   #final
        UNION ALL
        SELECT DISTINCT *
        FROM   #add_to_single
        UNION ALL
        SELECT *
        FROM   #onename) t
       LEFT JOIN #uniquepropdescr r
              ON t.RegisterPropertyDescription_Postcode =
                 r.RegisterPropertyDescription_Postcode

/*** Step 13. Reuploading the table - UNIQUE LEASES ***/
DROP TABLE [LandReg].[dbo].[ccodleasesidentified]

CREATE TABLE [LandReg].[dbo].[ccodleasesidentified]
  (
     TableID                                INT,
     UniqueIdentifier                       CHAR(40),
     RegisterPropertyDescription            VARCHAR(1000),
     RegisterPropertyDescription_Postcode   VARCHAR(10),
     County                                 VARCHAR(40),
     [AssociatedPropertyDescription ID]     BIGINT,
     AssociatedPropertyDescription          VARCHAR(255),
     AssociatedPropertyDescription_Postcode VARCHAR(10),
     UPRN                                   BIGINT,
     PricePaid                              MONEY,
     Term                                   VARCHAR(400),
     LeaseStart                             DATE,
     LeaseEnd                               DATE,
     Years                                  INT,
     StartDate                              DATE,
     Class_code                             VARCHAR(6),
     Class_desc                             VARCHAR(255),
     Primary_Desc                           VARCHAR(255),
     Secondary_Desc                         VARCHAR(255),
     Tertiary_Desc                          VARCHAR(255),
     VOA_NDR_RECORD                         BIGINT,
     PrimaryDescVOA                         VARCHAR(60),
     Title_no_leasehold_domestic            VARCHAR(9),
     CO_REG_NO_leaseholder_domestic_1       VARCHAR(50),
     Leaseholder_domestic_1                 VARCHAR(500),
     CO_REG_NO_leaseholder_domestic_2       VARCHAR(50),
     Leaseholder_domestic_2                 VARCHAR(500),
     Title_no_leasehold_overseas            VARCHAR(9),
     CO_REG_NO_leaseholder_overseas_1       VARCHAR(50),
     Leaseholder_overseas_1                 VARCHAR(500),
     CO_REG_NO_leaseholder_overseas_2       VARCHAR(50),
     Leaseholder_overseas_2                 VARCHAR(500),
     CO_REG_NO_leaseholder_overseas_3       VARCHAR(50),
     Leaseholder_overseas_3                 VARCHAR(500),
     CO_REG_NO_leaseholder_overseas_4       VARCHAR(50),
     Leaseholder_overseas_4                 VARCHAR(500),
     Title_no_freehold_domestic             VARCHAR(9),
     CO_REG_NO_Freeholder_domestic_1        VARCHAR(50),
     Freeholder_domestic_1                  VARCHAR(500),
     CO_REG_NO_Freeholder_domestic_2        VARCHAR(50),
     Freeholder_domestic_2                  VARCHAR(500),
     Title_no_freehold_overseas             VARCHAR(9),
     CO_REG_NO_Freeholder_overseas_1        VARCHAR(50),
     Freeholder_overseas_1                  VARCHAR(500),
     CO_REG_NO_Freeholder_overseas_2        VARCHAR(50),
     Freeholder_overseas_2                  VARCHAR(500),
     CO_REG_NO_Freeholder_overseas_3        VARCHAR(50),
     Freeholder_overseas_3                  VARCHAR(500),
     CO_REG_NO_Freeholder_overseas_4        VARCHAR(50),
     Freeholder_overseas_4                  VARCHAR(500),
     UpdateDate                             DATETIME
  )

TRUNCATE TABLE [LandReg].[dbo].[ccodleasesidentified];

INSERT INTO [LandReg].[dbo].[ccodleasesidentified]
            (TableID,
             UniqueIdentifier,
             RegisterPropertyDescription,
             RegisterPropertyDescription_Postcode,
             County,
             [AssociatedPropertyDescription ID],
             AssociatedPropertyDescription,
             AssociatedPropertyDescription_Postcode,
             UPRN,
             PricePaid,
             Term,
             LeaseStart,
             LeaseEnd,
             Years,
             StartDate,
             Class_code,
             Class_desc,
             Primary_Desc,
             Secondary_Desc,
             Tertiary_Desc,
             VOA_NDR_RECORD,
             PrimaryDescVOA,
             Title_no_leasehold_domestic,
             CO_REG_NO_leaseholder_domestic_1,
             Leaseholder_domestic_1,
             CO_REG_NO_leaseholder_domestic_2,
             Leaseholder_domestic_2,
             Title_no_leasehold_overseas,
             CO_REG_NO_leaseholder_overseas_1,
             Leaseholder_overseas_1,
             CO_REG_NO_leaseholder_overseas_2,
             Leaseholder_overseas_2,
             CO_REG_NO_leaseholder_overseas_3,
             Leaseholder_overseas_3,
             CO_REG_NO_leaseholder_overseas_4,
             Leaseholder_overseas_4,
             Title_no_freehold_domestic,
             CO_REG_NO_Freeholder_domestic_1,
             Freeholder_domestic_1,
             CO_REG_NO_Freeholder_domestic_2,
             Freeholder_domestic_2,
             Title_no_freehold_overseas,
             CO_REG_NO_Freeholder_overseas_1,
             Freeholder_overseas_1,
             CO_REG_NO_Freeholder_overseas_2,
             Freeholder_overseas_2,
             CO_REG_NO_Freeholder_overseas_3,
             Freeholder_overseas_3,
             CO_REG_NO_Freeholder_overseas_4,
             Freeholder_overseas_4,
             UpdateDate)
(SELECT TableID,
        UniqueIdentifier,
        RegisterPropertyDescription,
        RegisterPropertyDescription_Postcode,
        County,
        [AssociatedPropertyDescription ID],
        AssociatedPropertyDescription,
        AssociatedPropertyDescription_Postcode,
        UPRN,
        PricePaid,
        Term,
        LeaseStart,
        LeaseEnd,
        Years,
        StartDate,
        Class_code,
        Class_desc,
        Primary_Desc,
        Secondary_Desc,
        Tertiary_Desc,
        VOA_NDR_RECORD,
        PrimaryDescVOA,
        Title_no_leasehold_domestic,
        CO_REG_NO_leaseholder_domestic_1,
        Leaseholder_domestic_1,
        CO_REG_NO_leaseholder_domestic_2,
        Leaseholder_domestic_2,
        Title_no_leasehold_overseas,
        CO_REG_NO_leaseholder_overseas_1,
        Leaseholder_overseas_1,
        CO_REG_NO_leaseholder_overseas_2,
        Leaseholder_overseas_2,
        CO_REG_NO_leaseholder_overseas_3,
        Leaseholder_overseas_3,
        CO_REG_NO_leaseholder_overseas_4,
        Leaseholder_overseas_4,
        Title_no_freehold_domestic,
        CO_REG_NO_Freeholder_domestic_1,
        Freeholder_domestic_1,
        CO_REG_NO_Freeholder_domestic_2,
        Freeholder_domestic_2,
        Title_no_freehold_overseas,
        CO_REG_NO_Freeholder_overseas_1,
        Freeholder_overseas_1,
        CO_REG_NO_Freeholder_overseas_2,
        Freeholder_overseas_2,
        CO_REG_NO_Freeholder_overseas_3,
        Freeholder_overseas_3,
        CO_REG_NO_Freeholder_overseas_4,
        Freeholder_overseas_4,
        UpdateDate
 FROM   #final_updated) 