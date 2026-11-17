---
name: docentric-invoice-email-investigation
description: Use this skill when a customer reports that one or more sales, free-text or project invoices were not received by email.
metadata:
  author: 
	name: Docentric
  version: "1.2.0"
---
## Examples
| Request | What to do |
|---|---|
| Check why the invoices in this email were not sent. | Read the customer email, collect all invoices, run the flow below. |
| Check the invoices in the attached collection letter. | Read the attachment, collect its invoices, run the flow below. |
| The customer did not receive invoice CIV-000555 in USMF. | Run the flow for one invoice. |
| Why didn't the customer receive project invoice 000120 in USMF? | Project invoice. Keep the leading zeros. |
| The customer did not receive invoice CIV-000555. | Company missing. Ask for it before any check. |
| Did invoice CIV-000555 reach the customer's inbox? | Run the flow. Never claim inbox delivery: the system only shows that an email was sent. |

## Rules
- Invoice number and legal entity are mandatory before any data or form call. Reading the customer email may happen first.
- Prefer data entities. Use forms only where stated.
- Never state a cause the evidence does not support. Label conclusions Confirmed, Likely or Can't tell. If no reason is recorded, write "Reason not available".
- Never change print management settings.
- Never change customer contact information without asking first (Phase E).
- Never invent or propose an email address.
- A missing record is not proof that an action never happened. Use the markers Not found, Not checked, Could not be read. Never leave a value blank.
- Data can be changed by other users at any time. Always read the current values again at the start of each turn before writing, and report what you actually found.
- DISPLAY RULE: text written in the same turn before a question card is NOT shown to the user; only the final reply is shown. A render_ui card IS shown on screen as soon as it is called. Never write an overview, table or report as text before a question card in the same turn. To show findings before a question, put them in a render_ui card (Phase B); otherwise end the turn with the text. Keep question text to the question itself (Phase E may name the customer's current address situation, as specified there).

## Phase A - Collect (read only, no output yet)
1. Read the customer email (and the collection letter attachment if present). Collect:
     - all invoice numbers and the legal entity;
     - the address the customer asks to use (<requested address>), if any;
     - the sender address of the email (<sender address>).
   If an attachment cannot be read and is not the collection letter, say so. Do not claim that all invoices were extracted.
2. Identify all invoices in ONE query:
   SELECT h.InvoiceNumber, h.InvoiceDate, h.InvoiceCustomerAccountNumber, h.SalesOrderNumber FROM SalesInvoiceHeadersV4 h WHERE h.InvoiceNumber IN ('<inv1>','<inv2>',...)
    - Empty SalesOrderNumber = free text invoice.
    - Not found: try FreeTextInvoiceHeaders (FreeTextNumber, CustomerAccount, IsPosted).
    - Project invoices (plain numbers such as 000120): form ProjInvoiceListPage (Display), filterField ProjInvoiceJour.ProjInvoiceId, read ProjInvoiceJour_InvoiceAccount, close the form.
3. Read the email queue for ALL invoices in ONE form call:
   form_open_menu_item name SysOutgoingEmailTable, type Display, filterField OutgoingEmail_DocumentId_DC, filterValue '<inv1>,<inv2>,...' (comma-separated).
   For each row read: Document ID, Email recipients, Created date and time, Status, Context information. Then form_close_form.
    - Filter on Document ID, never on Email description (it holds the report name, e.g. Show invoice).
    - Several rows for one invoice: use the latest Created date and time. A later Sent row overrides an earlier Failed one.
    - Status Waiting (n): n = number of failed attempts. Waiting (0) = never attempted.
4. Only for invoices with NO queue row, check the print archive in ONE query:
   SELECT p.DocumentId, p.AccountNum, p.PrintDestination, p.PrintDestinationInfo, p.JournalType, p.CreatedDateTime1 FROM DocPrintJobHeaders p WHERE p.DocumentId IN (...) AND p.AccountNum = '<account>' ORDER BY p.CreatedDateTime1 DESC
    - Use the latest row. PrintDestination: Email, Printer, Screen, File, Archive. PrintDestinationInfo shows the real To address.
    - Destination not Email: the email was not sent because the print destination is not Email. Archive row with Email does not prove delivery.
5. Read the customer email addresses:
   SELECT a.ElectronicAddressId, a.Purpose, a.Locator, a.IsPrimary FROM CustomerElectronicAddresses a WHERE a.CustomerAccount = '<account>' AND a.Type = 'Email'
6. Resend list = invoices that have a queue row. If it is empty, report the findings (archive results, Not found) and stop.

## Phase B - Investigation results, then address choice (TURN 1, two separate parts)
Show what was found and what the user must decide as TWO separate parts, in this order. Never combine them in one block, never put the findings inside the question text, and never ask the user to reply OK.
- If the resend list is empty, do not ask: report the findings as the final reply and stop (Phase A step 6).
- If the user already named an address or option in the request, show Part 1, skip Part 2 and continue with Phase D in the same turn.

Part 1 - Investigation results (display only, no question)
- Call render_ui ONCE with a raw Adaptive Card {"type":"AdaptiveCard","version":"1.6","body":[...]}, with no text before it:
  - TextBlock "Investigation results" (size Large, weight Bolder).
  - FactSet: Company = <company>; Customer = <account> (<customer name>); Customer email addresses = <address (purpose)>, ... or "None on file"; Address requested in the email = <requested address> or "None"; Email sender = <sender address>.
  - Table with firstRowAsHeaders true and columns [{"width":15},{"width":13},{"width":14},{"width":22},{"width":11},{"width":25}]. Header row: Invoice | Type | Queued | Sent to | Status | Finding. One TableRow per invoice, in the order of the email; each TableCell holds one TextBlock.
  - Finding = short reason labelled Confirmed/Likely/Can't tell, or "Reason not available"; add "differs from the requested address" when Sent to is not <requested address>. Use "Not found" for missing values; for archive-only invoices put the print destination in Sent to and "Not in queue" in Status.
  - Every TextBlock has wrap true. No Input elements and no actions.
- Do not repeat the card's content as text later in the turn.
- If render_ui fails, fix the named errors and retry once. If it still fails, end the turn with a markdown section headed "Investigation results" (the same facts and table), followed by a separate line "Which address should I use to resend these invoices?" and the options below as a numbered list; continue with Phase D when the user answers.

Part 2 - Address question (user decision)
- Right after the card, ask with the selectable-options question tool. Header "Resend to". Question text exactly: "Which address should I use to resend these invoices?" - nothing else (no company, invoices, statuses or reasons).
- Options (show the real address in each description):
  1. Address from the email (<requested address>) - leave out if the email names none.
  2. Sender of the email (<sender address>).
  3. Enter a different address - then ask for it.
- Do not change anything before the answer.
- After the answer, run Phase D with no questions, then ask the Phase E question in the same turn.

## Phase D - Restart and update (same turn as the answer, no questions)
Emails with status Sent cannot be updated: the Update message button only appears when the status is Waiting, and the bulk update dialog only accepts Waiting, Failed or Expired emails. 
Therefore we will duplicate the selected record, change receipient, and restart the send.

1. Open SysOutgoingEmailTable filtered on the resend-list invoices (comma-separated Document ID filter).If there are more records for the Documetn ID, select the latest one (Created date and time).
2. Once the record is selected, click on the Message > Duplicate (DuplicateMessage_DC) button. The new row is created with the same recipient, status Expired. If the duplicate row is not created, report it in Phase G and continue with the next row.
3. Update and restart duplicated row:
   b. Click UpdateMessageButton_DC (Message > Update message).
   c. Set EmailRecipient to the chosen address. Keep Cc/Bcc unchanged.
   d. Click UpdateMessageButton (Update), then Yes in the confirmation.
   e. Restart the duplicated row: select and mark ONLY the duplicated row (it is Expired and has the new recipient), then click Restart send (ResetEmailButton) on the action pane. It is a separate button, not an item under the Message menu. If the restart fails, report it in Phase G and continue with the next row.
   f. Check the grid shows the new duplicate row and recipient in status Waiting.
4. If a step fails, retry it once; if it still fails, continue with the remaining rows and list the failure in Phase G. Do not stop to ask.
5. form_close_form.

## Phase E - Customer invoice email (ALWAYS ask)
1. Read the customer email addresses again (query in Phase A step 5).
2. Ask with the selectable-options question tool, no text before the card. Show ONLY the customer's current address situation and the question. Do not list the invoices, the resend results or the sending status here; they belong in the Phase G report.
   Question text: "Customer <account> (<customer name>) <current situation>. Do you want to update the customer's invoice email address to <chosen address>?"
   <current situation> is one of:
   - "currently has no email addresses on file, so it has no invoice email"
   - "has no invoice email; its current email addresses are <address (purpose)>, ..."
   - "currently has the invoice email <address>"
   - "already has <chosen address> as its invoice email"
   Example: "Customer US-002 (Contoso Retail Los Angeles) currently has no email addresses on file, so it has no invoice email. Do you want to update the customer's invoice email address to ap-invoices@contosoretail-la.com?"
   Options: "Yes, update it" / "No, leave it".
   After the answer, run step 3 or 4, then Phase F in the same turn.
3. Yes:
   - Invoice email with another address exists: update that row's Locator.
   - No Invoice email: create one in CustomerElectronicAddresses: CustomerAccount, Type Email, Locator <chosen address>, Description "Invoice email", Purpose Invoice, IsPrimary No.
   - Same address with Invoice purpose exists: change nothing and say so.
   Never change other rows, other purposes or the Primary flag. Fetch entity metadata (includeFieldConstraints, includeKeys) before the first write.
   If the write fails with the feature error 'Enable optimized entities to support data management of customers details', do not enable it; use the form fallback: All customers (CustTableListPage) > filter <account> (exactly one row) > Contact information > Add (Description "Invoice email", Type Email, address, Purpose Invoice, Primary not set) > Save > close forms. Any other error: quote it in Phase G.
   Read the addresses again to verify.
4. No: change nothing.

## Phase F - Reply to the customer email (ALWAYS ask, end of the process)
1. After Phase E, ask with the selectable-options question tool, no text before the card. Question text exactly: "Do you want me to create a reply to the customer's email?"
   Options:
   - "Yes, as a draft" - create the reply as a draft; do not send it.
   - "Yes, and send it" - create the reply and send it.
2. Reply (both Yes options): reply to the customer's email from <sender address>, keeping its subject. If the customer's message is only available inside a forwarded email, write a new email to <sender address> with subject "RE: <original subject>".
   Write in the language of the customer's email. Content: thank the customer; list each resent invoice and the address it was resent to (<chosen address>); if the invoice email was updated in Phase E, say that future invoices will be sent to that address; sign with the user's name.
   Do not attach files, do not claim the invoices reached the inbox, and do not add amounts, dates or promises that are not in the email or the data.
3. F&O has no mail access: the host's mail tools create the draft or send the email. If this fails, quote the error in Phase G.
4. Then give the Phase G report as the final reply of the same turn.

## Phase G - Final report (final reply of the turn)
- Table: | Invoice | Type | Old address | New address | Sending | Status |
- What happened to the customer's email addresses (verified by re-reading).
- Reply to the customer: draft created, sent to <address>, or not created.
- Any step that failed, with the error quoted.
- Still open: invoices still Waiting (0) after restart usually mean the email distributor batch job is not processing the queue (not verified unless checked). Status Sent means the email left the system, not that it reached the inbox.

## Reference - why an address was wrong (use when the user asks for the root cause)
Print management recipients can be literal addresses or purpose tokens:
- @Purpose@ (e.g. @Invoice@): all customer email addresses with that purpose; none need be primary.
- @@: the primary email address.
- @DLV_Purpose@: addresses on the document's delivery address. Not tested - state what is missing, do not guess.
- Advanced email tokens: definition in form DocAdvEmailToken. Not tested.
Invoice reports resolve tokens from the invoice account. If no address matches, Docentric applies its unresolved-token handling (warnings and fallback destinations are configurable). Vendor reports use vendor addresses; this skill covers customer invoices only.