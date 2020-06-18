/*
 * t1 support gl-cor:accountSub 2013-10-05 ns
 */
window.onload = function() {
    try {
        init(this);
    } catch(e) {
        alert(e);
    }
};
// implementation of our init function
function init(window) {
}

function glLoad() {
    var glSelectList = $('select#glselect');
    var href = $('option:selected', glSelectList).val();
    load_xmlfile(href);
}

// load xml file
function load_xmlfile(url) {
    //alert('load_xmlfile ' + url);
    $('#message').empty();
    var loc = "<a href='" + url + "' target='_blank'>" + url + "</a>";
    $('#message').append(loc);
    $.ajax({
        url : url,
        type : 'GET',
        dataType : 'text',
        timeout : 1000,
        error : fnc_xmlerr, //call "fnc_xmlerr" on failure
        success : fnc_xml   //call "fnc_xml" on success
    });
};
// Success
function fnc_xml(xml) {
    $("#trace").empty();
    //
    // accountingEntries
    $("#trace").append("<h2 align='left'>Accounting Entries</h2>");
    $accountingEntries = $(xml).find("gl-cor\\:accountingEntries");
    //
    // documentInfo
    $documentInfo = $accountingEntries.find("gl-cor\\:documentInfo");
        $entriesType = $documentInfo.find("gl-cor\\:entriesType");
        $uniqueID = $documentInfo.find("gl-cor\\:uniqueID");
        $language = $documentInfo.find("gl-cor\\:language");
        $creationDate = $documentInfo.find("gl-cor\\:creationDate");
        $creator = $documentInfo.find("gl-bus\\:creator");
        $entriesComment = $documentInfo.find("gl-cor\\:entriesComment");
        $periodCoveredStart = $documentInfo.find("gl-cor\\:periodCoveredStart");
        $periodCoveredEnd = $documentInfo.find("gl-cor\\:periodCoveredEnd");
        $sourceApplication = $documentInfo.find("gl-bus\\:sourceApplication");
        $defaultCurrency = $documentInfo.find("gl-muc\\:defaultCurrency");
    // Document Information table
    $table = $('<table width="97%" border="1" cellpadding="5"></table>');
    $("#trace").append($table);
    $table.append($("<tr style=\"color:#fff; background:#898;\"/>")
        .append($('<td width="30%"></td>').text("Document Information"))
        .append($('<td></td>').text("")));
    if ($entriesType.text())
        $table.append($("<tr/>")
            .append($('<td></td>').text("Entries Type"))
            .append($('<td></td>').text($entriesType.text())));
    if ($uniqueID.text())
        $table.append($("<tr/>")
            .append($('<td></td>').text("Unique ID"))
            .append($('<td></td>').text($uniqueID.text())));
    if ($language.text())
        $table.append($("<tr/>")
            .append($('<td></td>').text("Language"))
            .append($('<td></td>').text($language.text())));
    if ($creationDate.text())
        $table.append($("<tr/>")
            .append($('<td></td>').text("Creation Date"))
            .append($('<td></td>').text($creationDate.text())));
    if ($creator.text())
        $table.append($("<tr/>")
            .append($('<td></td>').text("Creator"))
            .append($('<td></td>').text($creator.text())));
    if ($entriesComment.text())
        $table.append($("<tr/>")
            .append($('<td></td>').text("Entries Comment"))
            .append($('<td></td>').text($entriesComment.text())));
    if ($periodCoveredStart.text())
        $table.append($("<tr/>")
            .append($('<td></td>').text("Period Covered Start"))
            .append($('<td></td>').text($periodCoveredStart.text())));
    if ($periodCoveredEnd.text())
        $table.append($("<tr/>")
            .append($('<td></td>').text("Period Covered End"))
            .append($('<td></td>').text($periodCoveredEnd.text())));
    if ($sourceApplication.text())
        $table.append($("<tr/>")
            .append($('<td></td>').text("Source Application"))
            .append($('<td></td>').text($sourceApplication.text())));
    if ($defaultCurrency.text())
        $table.append($("<tr/>")
            .append($('<td></td>').text("Default Currency"))
            .append($('<td></td>').text($defaultCurrency.text())));
    //
    // $entityInformation
    $entityInformation = $accountingEntries.find("gl-cor\\:entityInformation");
    $entityPhoneNumber = $accountingEntries.find("gl-bus\\:entityPhoneNumber");
        $phoneNumber = $entityPhoneNumber.find("gl-bus\\:phoneNumber");
    $entityFaxNumberStructure = $accountingEntries.find("gl-bus\\:entityFaxNumberStructure");
        $entityFaxNumber = $entityFaxNumberStructure.find("gl-bus\\:entityFaxNumber");
    $entityEmailAddressStructure = $accountingEntries.find("gl-bus\\:entityEmailAddressStructure");
        $entityEmailAddress = $entityEmailAddressStructure.find("gl-bus\\:entityEmailAddress");
    $organizationIdentifiers = $entityInformation.find("gl-bus\\:organizationIdentifiers");
        $organizationIdentifier = $organizationIdentifiers.find("gl-bus\\:organizationIdentifier");
        $organizationDescription = $organizationIdentifiers.find("gl-bus\\:organizationDescription");
    $organizationAddress = $accountingEntries.find("gl-bus\\:organizationAddress");
        $organizationAddressStreet = $organizationAddress.find("gl-bus\\:organizationAddressStreet");
        $organizationAddressCity = $organizationAddress.find("gl-bus\\:organizationAddressCity");
        $organizationAddressStateOrProvince = $organizationAddress.find("gl-bus\\:organizationAddressStateOrProvince");
        $organizationAddressZipOrPostalCode = $organizationAddress.find("gl-bus\\:organizationAddressZipOrPostalCode");
        $organizationAddressCountry = $organizationAddress.find("gl-bus\\:organizationAddressCountry");
    // Eentity Information table
    $table = $('<table width="97%" border="1" cellpadding="5"></table>');
    $("#trace").append($table);
    $table.append($("<tr style=\"color:#fff; background:#898;\"/>")
        .append($('<td width="30%"></td>').text("Eentity Information"))
        .append($('<td></td>').text("")));
    if ($phoneNumber.text())
        $table.append($("<tr/>")
            .append($('<td></td>').text("EntityPhoneNumber"))
            .append($('<td></td>').text($phoneNumber.text())));
    if ($entityFaxNumber.text())
        $table.append($("<tr/>")
            .append($('<td></td>').text("EntityFaxNumber"))
            .append($('<td></td>').text($entityFaxNumber.text())));
    if ($entityEmailAddress.text())
        $table.append($("<tr/>")
            .append($('<td></td>').text("EntityEmailAddress"))
            .append($('<td></td>').text($entityEmailAddress.text())));
    if ($organizationIdentifier.text())
        $table.append($("<tr/>")
            .append($('<td></td>').text("Organization Identifier"))
            .append($('<td></td>').text($organizationIdentifier.text())));
    if ($organizationDescription.text())
        $table.append($("<tr/>")
            .append($('<td></td>').text("Organization Description"))
            .append($('<td></td>').text($organizationDescription.text())));
    if ($organizationAddressStreet.text())
        $table.append($("<tr/>")
            .append($('<td></td>').text("Organization Address Street"))
            .append($('<td></td>').text($organizationAddressStreet.text())));
    if ($organizationAddressCity.text())
        $table.append($("<tr/>")
            .append($('<td></td>').text("Organization Address City"))
            .append($('<td></td>').text($organizationAddressCity.text())));
    if ($organizationAddressStateOrProvince.text())
        $table.append($("<tr/>")
            .append($('<td></td>').text("Organization Address State or Province"))
            .append($('<td></td>').text($organizationAddressStateOrProvince.text())));
    if ($organizationAddressZipOrPostalCode.text())
        $table.append($("<tr/>")
            .append($('<td></td>').text("Organization Address Zip or PostalCode"))
            .append($('<td></td>').text($organizationAddressZipOrPostalCode.text())));
    if ($organizationAddressCountry.text())
        $table.append($("<tr/>")
            .append($('<td></td>').text("Organization Address Country"))
            .append($('<td></td>').text($organizationAddressCountry.text())));
    //
    // entryHeader
    $entryHeaders = $accountingEntries.find("gl-cor\\:entryHeader");
    $entryHeaders.each(function(num, header) {
        $postedDate = $(header).find("gl-cor\\:postedDate");
        $enteredBy = $(header).find("gl-cor\\:enteredBy");
        $enteredDate = $(header).find("gl-cor\\:enteredDate");
        $sourceJournalID = $(header).find("gl-cor\\:sourceJournalID");
        $sourceJournalDescription = $(header).find("gl-bus\\:sourceJournalDescription");
        $entryOrigin = $(header).find("gl-bus\\:entryOrigin");
        $entryType = $(header).find("gl-cor\\:entryType");
        $entryNumber = $(header).find("gl-cor\\:entryNumber");
        $entryComment = $(header).find("gl-cor\\:entryComment");
        $bookTaxDifference = $(header).find("gl-cor\\:bookTaxDifference");
        // Header table
        $tableHeader = $('<table width="97%" border="1" cellpadding="5"></table>');
        $("#trace").append($tableHeader);
        $tableHeader.append($("<tr style=\"color:#fff; background:#898;\"/>")
            .append($('<td width="30%"></td>').text("Header " + (num+1)))
            .append($('<td></td>').text("")));
        if ($postedDate.text())
            $tableHeader.append($("<tr/>")
                .append($('<td></td>').text("Posted Date"))
                .append($('<td></td>').text($postedDate.text())));
        if ($enteredBy.text())
            $tableHeader.append($("<tr/>")
                .append($('<td></td>').text("Entered By"))
                .append($('<td></td>').text($enteredBy.text())));
        if ($enteredDate.text())
            $tableHeader.append($("<tr/>")
                .append($('<td></td>').text("Entered Date"))
                .append($('<td></td>').text($enteredDate.text())));
        if ($sourceJournalID.text())
            $tableHeader.append($("<tr/>")
                .append($('<td></td>').text("Source Journal ID"))
                .append($('<td></td>').text($sourceJournalID.text())));
        if ($sourceJournalDescription.text())
            $tableHeader.append($("<tr/>")
                .append($('<td></td>').text("Source Journal Description"))
                .append($('<td></td>').text($sourceJournalDescription.text())));
        if ($entryOrigin.text())
            $tableHeader.append($("<tr/>")
                .append($('<td></td>').text("Entry Origin"))
                .append($('<td></td>').text($entryOrigin.text())));
        if ($entryType.text())
            $tableHeader.append($("<tr/>")
                .append($('<td></td>').text("Entry Type"))
                .append($('<td></td>').text($entryType.text())));
        if ($entryNumber.text())
            $tableHeader.append($("<tr/>")
                .append($('<td></td>').text("Entry Number"))
                .append($('<td></td>').text($entryNumber.text())));
        if ($entryComment.text())
            $tableHeader.append($("<tr/>")
                .append($('<td></td>').text("Entry Comment"))
                .append($('<td></td>').text($entryComment.text())));
        if ($bookTaxDifference.text())
            $tableHeader.append($("<tr/>")
                .append($('<td></td>').text("Book Tax Difference"))
                .append($('<td></td>').text($bookTaxDifference.text())));
        // entryDetail
        $entryDetails = $(header).find("gl-cor\\:entryDetail");
        $entryDetails.each(function(line, detail) {
            $lineNumber = $(detail).find("gl-cor\\:lineNumber");
            $account = $(detail).find("gl-cor\\:account");
                $accountMainID = $account.find("gl-cor\\:accountMainID");
                $accountMainDescription = $account.find("gl-cor\\:accountMainDescription");
                $accountPurposeCode = $account.find("gl-cor\\:accountPurposeCode");
                $accountType = $account.find("gl-cor\\:accountType");
                $accountSub = $account.find("gl-cor\\:accountSub");
                    $accountSubDescription = $accountSub.find("gl-cor\\:accountSubDescription");
                    $accountSubID = $accountSub.find("gl-cor\\:accountSubID");
                    $accountSubType = $accountSub.find("gl-cor\\:accountSubType");
            $amount = $(detail).find("gl-cor\\:amount");
                $amountDecimals = $amount.attr('decimals');
                $amountUnitref = $amount.attr('unitRef');
            $amountMemo = $(detail).find("gl-bus\\:amountMemo");
            $identifierReference = $(detail).find("gl-cor\\:identifierReference");
                $identifierCode = $identifierReference.find("gl-cor\\:identifierCode");
                $identifierExternalReference = $identifierReference.find("gl-cor\\:identifierExternalReference");
                    $identifierAuthorityCode = $identifierExternalReference.find("gl-cor\\:identifierAuthorityCode");
                    $identifierAuthority = $identifierExternalReference.find("gl-cor\\:identifierAuthority");
                $identifierDescription = $identifierReference.find("gl-cor\\:identifierDescription");
                $identifierType = $identifierReference.find("gl-cor\\:identifierType");
                $identifierAddress = $identifierReference.find("gl-bus\\:identifierAddress");
                    $identifierStreet = $identifierAddress.find("gl-bus\\:identifierStreet");
                    $identifierCity = $identifierAddress.find("gl-bus\\:identifierCity");
                    $identifierStateOrProvince = $identifierAddress.find("gl-bus\\:identifierStateOrProvince");
                    $identifierCountry = $identifierAddress.find("gl-bus\\:identifierCountry");
                    $identifierZipOrPostalCode = $identifierAddress.find("gl-bus\\:identifierZipOrPostalCode");
            $documentType = $(detail).find("gl-cor\\:documentType");
            $documentNumber = $(detail).find("gl-cor\\:documentNumber");
            $documentReference = $(detail).find("gl-cor\\:documentReference");
            $documentDate = $(detail).find("gl-cor\\:documentDate");
            $documentLocation = $(detail).find("gl-bus\\:documentLocation");
            $maturityDate = $(detail).find("gl-cor\\:maturityDate");
            $terms = $(detail).find("gl-cor\\:terms");
            $measurable = $(detail).find("gl-bus\\:measurable");
                $measurableCode = $measurable.find("gl-bus\\:measurableCode");
                $measurableID = $measurable.find("gl-bus\\:measurableID");
                $measurableDescription = $measurable.find("gl-bus\\:measurableDescription");
                $measurableQuantity = $measurable.find("gl-bus\\:measurableQuantity");
                $measurableUnitOfMeasure = $measurable.find("gl-bus\\:measurableUnitOfMeasure");
                $measurableCostPerUnit = $measurable.find("gl-bus\\:measurableCostPerUnit");
                $measurableQualifier = $measurable.find("gl-bus\\:measurableQualifier");
            $depreciationMortgage = $(detail).find("gl-bus\\:depreciationMortgage");
                $dmJurisdiction = $depreciationMortgage.find("gl-bus\\:dmJurisdiction");
            $taxes = $(detail).find("gl-cor\\:taxes");
                $taxAuthority = $taxes.find("gl-cor\\:taxAuthority");
                $taxAmount = $taxes.find("gl-cor\\:taxAmount");
                $taxCode = $taxes.find("gl-cor\\:taxCode");
            $debitCreditCode = $(detail).find("gl-cor\\:debitCreditCode");
            $postingDate = $(detail).find("gl-cor\\:postingDate");
            $postingStatus = $(detail).find("gl-cor\\:postingStatus");
            $detailComment = $(detail).find("gl-cor\\:detailComment");
            // Detail table
            $tableDetail = $('<table class="detail" width="97%" border="1" cellpadding="5"></table>');
            $tableHeader.append($("<tr/>")
                .append($("<td  valign=\"top\" style=\"color:#333; background:#ded;\"></td>").text("... Detail " + (line+1)))
                .append($tableDetail));
            $tableDetail.append($("<tr style=\"color:#333; background:#ded;\"/>")
                .append($('<td width="30%"></td>').text("item"))
                .append($('<td></td>').text("value")));
            if ($lineNumber.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("Line Number"))
                    .append($('<td></td>').text($lineNumber.text())));
            if ($accountMainID.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("Account Main ID"))
                    .append($('<td></td>').text($accountMainID.text())));
            if ($accountMainDescription.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("Account Main Description"))
                    .append($('<td></td>').text($accountMainDescription.text())));
            if ($accountPurposeCode.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("Account Purpose Code"))
                    .append($('<td></td>').text($accountPurposeCode.text())));
            if ($accountType.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("Account Type"))
                    .append($('<td></td>').text($accountType.text())));
            if ($accountSubDescription.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("account Sub Description"))
                    .append($('<td></td>').text($accountSubDescription.text())));
            if ($accountSubID.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("account Sub ID"))
                    .append($('<td></td>').text($accountSubID.text())));
            if ($accountSubType.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("account Sub Type"))
                    .append($('<td></td>').text($accountSubType.text())));
            if($amountDecimals || $amountUnitref)
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("Amount"))
                    .append($('<td></td>').text($amount.text() + ' (decimals:' + $amountDecimals + ' unit:' + $amountUnitref + ')')));
            else
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("Amount"))
                    .append($('<td></td>').text($amount.text())));
            if ($amountMemo.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("Amount Memo"))
                    .append($('<td></td>').text($amountMemo.text())));
            if ($identifierCode.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("Identifier Reference / Identifier Code"))
                    .append($('<td></td>').text($identifierCode.text())));
            if ($identifierAuthorityCode.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("Identifier External Reference / Identifier Authority Code"))
                    .append($('<td></td>').text($identifierAuthorityCode.text())));
            if ($identifierAuthority.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("  Identifier Authority"))
                    .append($('<td></td>').text($identifierAuthority.text())));
            if ($identifierDescription.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("  Identifier Description"))
                    .append($('<td></td>').text($identifierDescription.text())));
            if ($identifierType.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("  Identifier Type"))
                    .append($('<td></td>').text($identifierType.text())));
            if ($identifierStreet.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("Identifier Address / Identifier Street"))
                    .append($('<td></td>').text($identifierStreet.text())));
            if ($identifierCity.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("  Identifier City"))
                    .append($('<td></td>').text($identifierCity.text())));
            if ($identifierStateOrProvince.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("  Identifier State or Province"))
                    .append($('<td></td>').text($identifierStateOrProvince.text())));
            if ($identifierCountry.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("  Identifier Country"))
                    .append($('<td></td>').text($identifierCountry.text())));
            if ($identifierZipOrPostalCode.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("  Identifier Zip or Postal Code"))
                    .append($('<td></td>').text($identifierZipOrPostalCode.text())));
            if ($documentType.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("Document Type"))
                    .append($('<td></td>').text($documentType.text())));
            if ($documentNumber.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("Document Number"))
                    .append($('<td></td>').text($documentNumber.text())));
            if ($documentReference.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("Document Reference"))
                    .append($('<td></td>').text($documentReference.text())));
            if ($documentDate.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("Document Date"))
                    .append($('<td></td>').text($documentDate.text())));
            if ($documentLocation.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("Document Location"))
                    .append($('<td></td>').text($documentLocation.text())));
            if ($maturityDate.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("Maturity Date"))
                    .append($('<td></td>').text($maturityDate.text())));
            if ($terms.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("Terms"))
                    .append($('<td></td>').text($terms.text())));
            // measurable
            if ($measurableCode.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("Measurable Code"))
                    .append($('<td></td>').text($measurableCode.text())));
            if ($measurableID.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("Measurable ID"))
                    .append($('<td></td>').text($measurableID.text())));

            if ($measurableDescription.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("Measurable Description"))
                    .append($('<td></td>').text($measurableDescription.text())));
            if ($measurableQuantity.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("Measurable Quantity"))
                    .append($('<td></td>').text($measurableQuantity.text())));
            if ($measurableUnitOfMeasure.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("Measurable Unit of Measure"))
                    .append($('<td></td>').text($measurableUnitOfMeasure.text())));
            if ($measurableQualifier.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("Measurable Qualifier"))
                    .append($('<td></td>').text($measurableQualifier.text())));
            if ($dmJurisdiction.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("Depreciation Mortgage / dm Jurisdiction"))
                    .append($('<td></td>').text($dmJurisdiction.text())));
            if ($measurableCostPerUnit.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("Measurable Cost Per Unit"))
                    .append($('<td></td>').text($measurableCostPerUnit.text())));
            if ($taxAuthority.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("Tax Authority"))
                    .append($('<td></td>').text($taxAuthority.text())));
            if ($taxAmount.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("Tax Amount"))
                    .append($('<td></td>').text($taxAmount.text())));
            if ($taxCode.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("Tax Code"))
                    .append($('<td></td>').text($taxCode.text())));
            if ($debitCreditCode.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("Debit Credit Code"))
                    .append($('<td></td>').text($debitCreditCode.text())));
            if ($postingDate.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("Posting Date"))
                    .append($('<td></td>').text($postingDate.text())));
            if ($postingStatus.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("Posting Status"))
                    .append($('<td></td>').text($postingStatus.text())));
            if ($detailComment.text())
                $tableDetail.append($("<tr/>")
                    .append($('<td></td>').text("Detail Comment"))
                    .append($('<td></td>').text($detailComment.text())));
        });
    });
};
// Error
function fnc_xmlerr() {
    alert("Fail to load file.");
};
