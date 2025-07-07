`{{SiteInfobox
|thumbnail=[[File:osh.jpg|thumb|center]]
|organization=Oshkosh Cold Storage
|release-date=
|live-urls=https://tracker.oshkoshcheese.com/
|live-servers=chimera
|staging-urls=
|staging-servers=
|dev-urls=https://tracker.fergdev.com/
|dev-servers=arrokoth
|server-path=/web/html/tracker.oshkoshcheese.com/
|database-engine=
|dev-database-server=
|live-database-server=Helios
|database-name=
|platform-language=PHP / Phalcon MVC Framework
|ada-standard=
|github-repo=[https://github.com/Ferguson-Digital/tracker.oshkosh Ferguson-Digital/tracker.oshkosh]
|lead-dev=[[User:ric@fia2.com|Ric]]
|previous-dev=
|account-contact=[[User:Shelly@fai2.com|Shelly]]
|web-health=-
|analyst=
|dash1=
|dash2=
|dash3=
|dash4=
|dash5=
}}`{=mediawiki}

## History

Oshkosh Cold Storage is an entity in Wisconsin that has warehouses for
Cold Storage in three cities in Wisconsin. They store cheese for aging
and redistribution. They track nearly 300 tons of cheese at any given
time.

In about 2010, Oshkosh Cold Storage in Oshkosh Wisconsin came to us and
asked us to re-implement a piece of software that they had. This became
tracker.oshkoshcheese.com. The old software was in Windows NT, and cost
more to update than what our implementation of the software cost to
build.

Not too long after they asked us to implement EDI integration for Great
Lakes cheese into the tracker site. This was not part of the original
Bill nor was it part of their old software. EDI is a way of
communicating common documents like ship notices, orders, invoices, etc.
via [ANSI X12](https://x12.org/) data sets. We use the AS2
communications protocol to talk to the customer service and to bring
back data into our server. We run a local instance of an AS2
communication server, running open AS2. The development server does not
actually communicate with the outside world, but exists to be a parallel
endpoint for data to mirror the live server.

See [AS2 Server
Stuff](Tracker.oshkoshcheese.com#AS2_Server_Stuff "AS2 Server Stuff"){.wikilink}
later in this document.

## Glossary

**Offer**: a potential sale of stock.

**Lot**: A collection of vats of a single Product Code for a single
Vendor (manufacturer)

**Vat**: A literal vat that equates to a QC batch number in case a vat
is contaminated, we track that.

**Manifest**: Everything in a lot or everything on a shipment

**Bill of Lading:** The paperwork that\'s handed to a truck driver. It
lists all of the critical information including what cheese is in the
load.

**License Plate:** An SSCC number that is governed by gs1us.org it is an
18 digit numeric barcode that goes on any shippable container at any
level. You can go on a pallet it can go on a truck it can go on a train
car it can go any shipping container. It allows you to track a shipment
anywhere in the world through United Network. They are unique across the
board and Oshkosh has a 10 or 11 digit number that begins that code and
then the last seven digits is a serial number of which package we\'re
referring to within the system. License plate should be unique with the
system, but we realized that that is not the case. Some license plates
get sent to us but the package never got to us so they get sent on the
next order with a package actually shipped with the same license plate.
So don\'t count on it as a unique field.

**Incoming EDI transaction**: a transaction is coming into tracker from
an outside company.

**Outgoing EDI transaction**: a transaction that tracker should be
sending the company.

**Batch number:** an internal number is signed by Oshkosh storage that
uniquely to identifies each lot in the system. It\'s generally six
digits and it is assigned by a different system and hand entered when
you create a new lot.

**Draft Lot:** What EDI creates and then it\'s sanity check by human
before it gets promoted to an actual lot.

**Pending offer:** what EDI generates as an outgoing order, but a human
being sanity checks it before it becomes an actual offer.

## Logging Errors

Errors are stored in both

`/web/logs/.../errors (php errors) `

and

`/web/logs/.../debug (programmer generated logs)`

There is a command on **arrokoth** and **chimera** called `logt` that
works exactly like `log` (with tab-extension) but it\'ll tail BOTH the
error and debug logs.

**Example:**

`logt Ric/tracker.oshkoshcheese.com`

## Common Support issues

### We didn\'t get incoming with DN# 8999999999

This is almost exclusively a License Plate Issue. If you search the EDI
Document list (/edidocument/list) for that DN# (it\'s a long number that
begins with 8), you see that the document is likely a 943 with Status of
\"Translated\" and not \"imported\" like the other 943 documents. Follow
steps in [#License Plate
Issues](#License_Plate_Issues "#License Plate Issues"){.wikilink}

### Pending Offer is Missing EDI Information

Pending offers screen looks like this (with missing EDI#)

![Pending-offers.png](images/Pending-offers.png "Pending-offers.png")

Solution: Click on offer that\'s missing information.

Look at offer notes for **EDI#.**

![Onotes.png](images/Onotes.png "Onotes.png")

**OFFER ID** is in the URL

Follow instructions at: [#Assign an EDI ID to an
offer](#Assign_an_EDI_ID_to_an_offer "#Assign an EDI ID to an offer"){.wikilink}

### Outbound wasn\'t sent

Means: The loading doc shipped it, but no EDI went out. This will only
work if the transaction number is 940 They should give you a customer PO

Fix:

``` SQL
-- get BOLID
select BOLID from BillOfLading where CustomerPO = '741355';
-- reset it to unshipped.
update BillOfLading set StatusPID = '1E732327-AD3E-42C1-9602-F505B3A75E7E' where BOLID = '15EDA291-64CA-421C-BDFB-C2C91AFFAABA';
```

Then go back to shipping screen
(https://tracker.oshkoshcheese.com/billoflading/shipdetail/BOLID) and
mark all lines shipped and send EDI. Watch the debug/error logs for
errors. I have no idea why it misses this sometimes, but it just started
happening.

## Billing Reports

There are separate (but related) billing report tools for storage and
for curing. They can be accessed from the Customers page by clicking
Reports next to a particular customer in the list. The storage report is
for \"AGING\" inventory, and the curing report is for \"SET-ASIDE\"
inventory, as denoted per lot in the system.

Both reports use endpoints defined in CustomerController.php to output
XLSX files for the selected customer, date range, and warehouse(s).

Think of these reports as a list of the rent payments that the customer
owes for the month, divvied up by the individual lots where they are
storing/curing their cheese. Each lot keeps getting charged
month-by-month while it still has cheese in it, and the charge depends
on the amount of cheese that was still in the lot at the beginning of
the billing cycle. This has traditionally been done by weight, but will
also be done by pallet, once that system is in place.

The start date of each lot\'s monthly billing cycle depends on the
anniversary date of that lot\'s first entry. For example, say we are
billing for August 2020. The customer has a lot that was entered on Jan
10, 2018 and still has cheese in it. That means that the lot incurs a
charge for the billing cycle of Aug 10 - Sep 9.

Things get a little tricky for anniversary dates that occur on the 29th,
30th, or 31st, because of the varying lengths of months. For example, if
a lot was entered on Jan 31, then it will have a billing cycles like the
following (assuming no leap year for the sake of example).

- Jan 31 - Feb 27
- Feb 28 - Mar 30
- Mar 31 - Apr 29
- Apr 30 - May 30
- etc.

## EDI Documents

EDI is a module we developed for Oshkosh in order to keep track of the
flow of orders, both incoming and outgoing. For a view of all the
current EDI documents, you can click on the \"EDI Management\" tab under
EDI.

### EDI Document Types

- 943 - Incoming Order
- 944 - Confirmation of incoming received \"we got it\"
- 940 - Outgoing Order
- 945 - Confirmation of outgoing order shipped

### General Incoming EDI Document Flow

When an EDI order comes in, it will go into Incoming Deliveries under
EDI. The next step is to mark the order(s) as received and then convert
them to draft lots. To do this, follow these steps:

- Click into the delivery you want to receive
- Check the \"Rec\'d\" box on the left side of the Batch list or you can
  click the \"Mark All Received\" button
- Click the \"Confirm and Convert to Draft Lots\" button

Next, to see the received deliveries, click on \"See Draft Lots\" and
click on one in the list. When dealing with a draft lot, there are three
things that need to be updated for the process to continue.

- The Lot Number must be populated
- A Room must be assigned
- The Status needs to be changed from **Draft** to **Existing**

Once those three things are updated, click \"Save the Lot Info\".

### General Outgoing EDI Document Flow

To process an outgoing EDI document follow these steps:

- Click into \"Incoming Orders\" under the \"Orders\" tab
- Click on an order in the list
- Click on the \"Convert to Offer\" button - This will create a pending
  offer
- Go to Pending Offers - A link should be provided in the process of the
  previous step or you can navigate there under the \"Orders\" tab in
  EDI
- Click on the Pending Offer that you would like to process
- Click on \"Mark as Sold\" to process the Offer
- Print a BOL (Bill of Lading) - You don\'t actually have to physically
  print the sheet when testing this
- Got to the shipping module and click on the EDI shipment you are
  wanting to process - Note: There should be an EDI# on the right side
  of the table to denote this
- Select the batches to be shipped or click the \"Mark All Shipped\"
  button
- Click the \"Confirm and Send EDI\" button

### EDI CRON Job

There is a CRON job that runs about every 5 minutes that will send any
order with a status of outbox.

## Hacks

### Assign an EDI ID to an offer

Example:

URL: `/offer/edit/BFA6BD8B-A614-45E9-8CE0-99C4F55BA5A3` EDI ID (from
notes): 3565 NEW OFFER ID (from URL):
BFA6BD8B-A614-45E9-8CE0-99C4F55BA5A3

``` sql
UPDATE CustomerOrder SET OfferID = 'BFA6BD8B-A614-45E9-8CE0-99C4F55BA5A3' where EDIDocID = 3565;
```

1.  Refresh Screen
2.  Click BOL in top button bar
3.  Click \'Save\'
4.  Copy BOL ID from URL (Ex: D6DD138A-9EAB-423F-A780-458116CAEBD3 )
5.  Go to: `/billoflading/shipdetail/BOLID`
6.  Re-ship the order to send EDI.

### Reset EDI Offers from \"Expired\" to \"EDIPending\"

#### By EDI ID

Note: This will take 1.5 - 2 minutes to process.

``` {.sql .numberLines}
UPDATE Offer 
SET OfferStatusPID = 'C478D7C5-25FC-439B-A5A4-A155493ABC08' 
WHERE OfferID IN (SELECT OfferID FROM CustomerOrder WHERE EDIDocID IN (143,147));
```

#### Or By OfferID

Example, for this Offer:

`/offer/edit/4230408C-6C23-42FA-B447-CC45316ABE69`

``` {.sql .numberLines}
update Offer set OfferStatusPID = 'C478D7C5-25FC-439B-A5A4-A155493ABC08' where OfferID = '4230408C-6C23-42FA-B447-CC45316ABE69';
```

### Reset Non-EDI Offers from \"Expired\" to \"Open\"

#### Or By OfferID

Example, for this Offer:

`/offer/edit/4230408C-6C23-42FA-B447-CC45316ABE69`

``` {.sql .numberLines}
update Offer set OfferStatusPID = '9A085965-75B4-4EE2-85A8-02D61924DCC8' where OfferID = '4230408C-6C23-42FA-B447-CC45316ABE69';
```

## License Plate Issues

### Patch Duplicate License plate

1\) tail the error and debug logs

`tail -f /web/logs/tracker.oshkoshcheese.com/error /web/logs/tracker.oshkoshcheese.com/debug`

2\) attempt to re-run import

[`https://tracker.oshkoshcheese.com/edidocument/x12tojson/943/GLC/EDIDOCID`](https://tracker.oshkoshcheese.com/edidocument/x12tojson/943/GLC/EDIDOCID)

Error log will show duplicate license plate

Fix the whole delivery:

``` {.sql .numberLines}
SELECT DeliveryID FROM DeliveryDetail WHERE LicensePlate = '1942102789'; -- get DELIVERYID
UPDATE DeliveryDetailReceipt SET LicensePlate = DeliveryDetailID WHERE DeliveryDetailID IN (SELECT DeliveryDetailID FROM DeliveryDetail WHERE DeliveryID = DELIVERYID);
UPDATE DeliveryDetail SET LicensePlate = DeliveryDetailID WHERE DeliveryID = DELIVERYID;
```

Note, the status of the ID they want resolved is converted do this flow
instead:

``` {.sql .numberLines}
DELETE from Delivery where EDIDocID = EDIDocID;
DELETE from DeliveryDetail where EDIDocID = EDIDocID;
UPDATE EDIDocument set status = 'Translated' where DocID = 21336;

UPDATE DeliveryDetailReceipt SET LicensePlate = DeliveryDetailID WHERE DeliveryDetailID IN (SELECT DeliveryDetailID FROM DeliveryDetail WHERE DeliveryID = DELEIVERYID);
UPDATE DeliveryDetail SET LicensePlate = DeliveryDetailID WHERE DeliveryID = DELIVERYID;
```

3\) Do this to re-run import:

[`https://tracker.oshkoshcheese.com/edidocument/x12tojson/943/GLC/EDIDOCID`](https://tracker.oshkoshcheese.com/edidocument/x12tojson/943/GLC/EDIDOCID)

### If You Have Internally Duplicate License Plates

If they give you a PO (Reference) number that they say is missing, so
you don\'t know what the duplicate LPN is (assuming it\'s a dupe), go to
the EDI document list
(https://tracker.oshkoshcheese.com/edidocument/list) and find the PO in
the list. Get the DocID from the first column.

Then:

``` {.sql .numberLines}
UPDATE EDIDocument SET Status = 'New', JsonObject = '' WHERE DocID = <docid>;
```

Tail the error log and run this \"conversion script\":

`chimera 14:08:20 > php /web/html/tracker.oshkoshcheese.com/public/edi/translateNew.php`

If there\'s a duplicate LPN, you\'ll see an error like this:

    PHP Fatal error:  Uncaught PDOException: SQLSTATE[23000]: Integrity constraint violation: 1062 Duplicate entry '365140261703990' for key 'LicensePlate' in /web/html/tracker.oshkoshcheese.com/app/controllers/EdidocumentController.php:931

Get the path to the X12 file that has the problem:

``` {.sql .numberLines}
SELECT X12FilePath FROM EDIDocument WHERE DocID = <docid>;
```

Edit the file and search for the duplicate key, which will be preceeded
by **LV\*** and followed by **\~N9\***. Change the key, maybe by adding
\".1\" to the end of it (before **\~N9\***). If there is more than one
occurrence of the LPN, add \".2\" to the next, and so on. Each LPN must
be unique.

Re-run the conversion script. Note that you may still get an error
because there is yet another duplicate in there. I edited a file that
had about 40 LPNs in it, every single one of them different from each
other, but a duplicate of something we had already seen.

Once the file imports cleanly, they should be back in business.

### Reset Incoming Delivery to Pending to be received again

``` {.sql .numberLines}
UPDATE Delivery SET StatusPID = '51398435-A4A6-4C41-ACC8-45F6D569057B' WHERE DeliveryID = <delivery_id>;
```

## Delete and Rerun Delivery by EDIDocID

``` {.sql .numberLines}
SELECT DeliveryID from Delivery WHERE EDIDocID = 15710;
DELETE FROM DeliveryDetailReceipt WHERE DeliveryDetailID IN (SELECT DeliveryDetailID FROM DeliveryDetail WHERE DeliveryID = 3052);
DELETE FROM DeliveryDetail WHERE DeliveryID = 3052;
DELETE FROM Delivery WHERE DeliveryID = 3052;
UPDATE EDIDocument SET Status = 'Translated' WHERE DocID = 15710;
-- Then re-run import.
-- https://tracker.oshkoshcheese.com/edidocument/x12tojson/943/GLC/15710
```

## Common Deletes

### Delete draft lots by EDI ID

``` {.sql .numberLines}
delete from Lot where DeliveryID in (select DeliveryID from Delivery where EDIDocID in (4750,4558,4273));
```

### Delete All Traces of Lot by LotNumber

``` {.sql .numberLines}
SELECT LotID as '<lotid>' FROM Lot WHERE LotNumber = '263966';
DELETE FROM InventoryStatus WHERE VatID in (SELECT VatID from  Vat WHERE LotID = '<lotid>');
DELETE FROM Vat WHERE LotID = '<lotid>';
DELETE FROM Lot WHERE LotID = '<lotid>';
```

### Delete All Traces of Vat by VatID

``` {.sql .numberLines}
DELETE FROM InventoryStatus WHERE VatID = '<vatid>';
DELETE FROM Vat WHERE VatID = '<vatid>';
```

### Delete All Traces of Offer by OfferID

``` mysql
DELETE FROM BillOfLading WHERE OfferID = '<offerid>';
DELETE FROM OfferItemVat WHERE OfferItemID IN (SELECT OfferItemID from OfferItem WHERE OfferID = '<offerid>');
DELETE FROM OfferItem WHERE OfferID = '<offerid>';
DELETE FROM Offer WHERE OfferID = 'offerid';
```

## Clean up Pending Offers

### Expire GLC offers without EDIDocIDs

``` {.sql .numberLines}
SELECT o.OfferID
FROM Offer o
LEFT OUTER JOIN CustomerOrder co ON co.OfferID = o.OfferID
WHERE o.OfferStatusPID = 'C478D7C5-25FC-439B-A5A4-A155493ABC08' 
AND o.CustomerID = '62B545A4-9C0D-430C-A88C-5CB37CC8EBEA' AND EDIDocID IS NULL;

-- With results

UPDATE Offer uo SET uo.OfferStatusPID = '319FB16C-19F5-4364-82E3-93AD7627AF38' where uo.OfferID in (
'05B596D2-F275-4917-976E-1EBB14F6AD9E',
'06FD89AF-3B9A-4C2B-8A7F-21DD25F1DBD9',
'7509C433-7C58-47D2-A124-230C085DDDC2',
'76265073-F09E-46D0-848B-C3A27BA175AA',
'9942D22F-234F-473F-9A08-4DBA7B8F777F',
'A611140E-CFCB-4664-9B7C-EC3739224008',
'B36A3A99-99A9-4A93-B273-B8C002CAAA03',
'BA233AD0-BB01-46E2-A1F3-685ADA485FC1',
'D51BEFB4-7F0F-4090-B148-C9237CB91C9E',
'E3DA8396-8B78-44B0-AFDE-A31476DD865F',
'F3E5DA8B-410F-4305-A710-80D4946B4644');
```

### Expire specific EDI Doc IDs

``` {.SQL .numberLines}
SELECT o.OfferID
FROM Offer o
LEFT OUTER JOIN CustomerOrder co ON co.OfferID = o.OfferID
WHERE o.OfferStatusPID = 'C478D7C5-25FC-439B-A5A4-A155493ABC08' 
AND o.CustomerID = '62B545A4-9C0D-430C-A88C-5CB37CC8EBEA' AND EDIDocID in(2076, 2677);

-- With results

UPDATE Offer uo SET uo.OfferStatusPID = '319FB16C-19F5-4364-82E3-93AD7627AF38' where uo.OfferID in (
'A2594FED-6EA0-4D3D-ABE9-92C5B1B65AC4', 'DF7678DA-0D2D-4606-9D22-D5E0E5554C59' );
```

## Remove Offer from Shipping Screen

Given offer link

[`https://tracker.oshkoshcheese.com/offer/edit/5A496060-0DBC-4D48-A8EB-8B27B5070885`](https://tracker.oshkoshcheese.com/offer/edit/5A496060-0DBC-4D48-A8EB-8B27B5070885)` `

Offer ID is:

`5A496060-0DBC-4D48-A8EB-8B27B5070885`

``` mysql
DELETE FROM BillOfLading WHERE OfferID = '5A496060-0DBC-4D48-A8EB-8B27B5070885';
```

## When EDI# and PONum are missing from a pending offer

1.  Get Offer ID from URL (Say
    <https://tracker.oshkoshcheese.com/offer/edit/32ABE2B6-FA5F-4BCA-B86D-298B1CAFC1B6>
    )
2.  That makes it: `32ABE2B6-FA5F-4BCA-B86D-298B1CAFC1B6`
3.  Look at offer page. EDI# is in notes.
4.  Verify it\'s the right offer, this should be null:

``` sql
select OfferID from CustomerOrder where EDIDocID = 14432;
```

5\. then:

``` sql
UPDATE CustomerOrder SET OfferID = '32ABE2B6-FA5F-4BCA-B86D-298B1CAFC1B6' where EDIDocID = 14432;
```

### Find Them All

This OfferStatusPID is \"Pending\"

``` sql
select OfferID, REGEXP_SUBSTR(Note,"[0-9]+") AS EDIDocID from Offer where OfferStatusPID = 'C478D7C5-25FC-439B-A5A4-A155493ABC08';
```

Take results into VSCode and hack it to something like:

``` sql
UPDATE CustomerOrder SET OfferID = '174607F0-512C-4F61-99F4-B0D799AFEB11' where EDIDocID = 13303;
UPDATE CustomerOrder SET OfferID = '26FAA577-28B1-46B7-BA00-1FDEE05640AC' where EDIDocID = 14428;
UPDATE CustomerOrder SET OfferID = '47967696-947C-44BF-B61F-0F82F1460615' where EDIDocID = 11199;
```

## Inventory Management

**Get all vats in a Lot:**

`mysql> call vats('``<lot-number or lot-id>`{=html}`');`

**Get inventory status of a vat:**

`mysql> call inv('``<vat-id>`{=html}`');`

**Update Various Statii:**

``` mysql
 --offered
UPDATE InventoryStatus SET Pieces=0, Weight=0 
WHERE InventoryStatusPID = 'C67C99CD-492D-4227-92E3-0A3B8DF6EEC8' AND VatID = '<vat-id>';

 --avail
UPDATE InventoryStatus SET Pieces=0, Weight=0 
WHERE InventoryStatusPID = 'D99FC80E-52BC-4AD0-9B10-3E5A5F07EAE0' AND VatID = '<vat-id>';

 --unavail
UPDATE InventoryStatus SET Pieces=120, Weight=720
WHERE InventoryStatusPID = '235E42CD-31BE-42F0-983A-24675305ED04' AND VatID = '<vat-id>';

 -- sold/unshipped
UPDATE InventoryStatus SET Pieces=0, Weight=0
WHERE InventoryStatusPID = 'D6BB15FC-BA12-46A2-A5EE-9CCCB5BCAC5E' AND VatID = '<vat-id>';
```

**Note:**

*Unavailable* should always move the same amount as *Available* but in
the other direction. That is, if you subtract 4 from *available*,
you\'ll likely need to add 4 to *unavailable*.

*Unavailable* + *Available* should always = Pieces and Weight in Vat
record thusly:

``` mysql
SELECT Pieces, Weight FROM Vat WHERE VatID = '<vat-id>';
```

\"Offered\" is almost never right, but I\'m fixing that.

## Add Line to Outbound 945

``` mysql
SELECT CustomerOrderID, EDIDocID, CustomerOrderNum, OfferID, CustPONum FROM CustomerOrder WHERE CustomerOrderNum LIKE '%85271433';

INSERT INTO CustomerOrderDetail 
( CustomerOrderID, EDIDocID, LineNum, Qty, QtyUOM, PartNum, ShipToPartNum, POLine ) 
VALUES ( 5103, 34792, 19, 85, 'CA', '174827', '174827', '000190');
```

### Example

This case they sent an updated order too late, so updates, not inserts
are required

`CO 5805 original order`\
`CO 5882 updated order`\
`skus added on 5882`\
` 170571 and 170570`

This code finds the 2 orders and you can identify by sku which lines to
move from 5882 to 5805. It\'s vital to change both CustomerOrderID and
the EDI DocID. LineNum probably doesn\'t matter.

You should avoid duplicate POLines, but they are usually fine.

``` mysql
-- Find BOTH Orders:
select * from CustomerOrder where CustomerOrderNum like '%85315262' OR ShipToPONum like '%85315262';
-- Find BOTH orders' lines
SELECT * FROM CustomerOrderDetail WHERE CustomerOrderID IN (5805, 5882) ORDER BY EDIDocID;
-- move two lines FROM 5882 TO 5805
UPDATE CustomerOrderDetail SET CustomerOrderID = 5805, EDIDocID = 39343 WHERE CustomerOrderDetailID IN (65530,65531);
-- CHECK FOR LineNum anbd POLine discrepancies
SELECT * FROM CustomerOrderDetail WHERE CustomerOrderID IN (5805);
-- fix LineNums
UPDATE CustomerOrderDetail SET LineNum = 15 WHERE CustomerOrderDetailID = 65530;
UPDATE CustomerOrderDetail SET LineNum = 16 WHERE CustomerOrderDetailID = 65531;
```

## AS2 Server Stuff

### General Information

The scripts for manually processing things sit at:

`/web/html/as2.oshkoshcheese.com/`

On both dev and live servers, the as2 data sits at:

`/web/html/as2.oshkoshcheese.com/openas2/data/`

The inboxes are in `/web/html/as2.oshkoshcheese.com/openas2/data/`:

`GLC: 018219808-OCS_AS2/inbox`\
`SAPuto: SAPUTOUSA-OCS_AS2/inbox`\
`SALM Partners: TrueCommerceSHA2-OCS_AS2/inbox`

The outboxes are in `/web/html/as2.oshkoshcheese.com/openas2/data/`:

`toGreatLakes/`\
`toSAPUTOUSA/`

### Restart AS2 server on Chimera

If there are things in the inbox, but haven\'t made it to tracker:

`chimera> sudo /etc/init.d/as2-openas2 start`

or

`chimera> sudo /etc/init.d/as2-openas2 restart`

### Manually receiving EDI documents for GLC

Copy any .edi files from Silvia to:

`/web/html/as2.oshkoshcheese.com/openas2/data/018219808-OCS_AS2/inbox`

## Latest GitHub Commits

*This section is automatically generated. If you add anything below
this, it will probably get deleted.*

- Last commit to master branch of
  [Ferguson-Digital/tracker.oshkosh](https://github.com/Ferguson-Digital/tracker.oshkosh)
  was at **10:30** on **Tuesday, November 1, 2022** by **Robert**: [See
  the
  commit](https://github.com/Ferguson-Digital/tracker.oshkosh/commit/35954bfaa843dbea364c59648c757027f5d3061d)

[Category:Sites](Category:Sites "Category:Sites"){.wikilink}
