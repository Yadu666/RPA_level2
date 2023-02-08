*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.Tables
Library             RPA.HTTP
Library             RPA.PDF
Library             RPA.Archive
Library             Collections
Library             RPA.Dialogs
Library             RPA.Robocloud.Secrets
Library             OperatingSystem
Library             Dialogs


*** Variables ***
${receipt_dir}      ${OUTPUT_DIR}${/}receipts/
${sshot_dir}        ${OUTPUT_DIR}${/}screenshot/
${zip_dir}          ${OUTPUT_DIR}${/}


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${Orders}=    Get orders
    Open the robot order website
    FOR    ${row}    IN    @{Orders}
        Close the annoying modal
        Fill the form    ${row}
        Wait Until Keyword Succeeds    10x    2s    Preview the robot
        Wait Until Keyword Succeeds    10x    2s    Submit the order
        ${pdf}=    Store the receipt as a PDF    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the reciept pdf file    ${screenshot}    ${pdf}
        Go to another robot
    END
    Create zip file with receipts
    Delete screenshots and receipts
    Close the Browser


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order    auto_close=${FALSE}

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${tab}=    Read table from CSV    orders.csv
    RETURN    ${tab}

Fill the form
    [Arguments]    ${roww}
    Select From List By Value    head    ${roww}[Head]
    Select Radio Button    body    ${roww}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${roww}[Legs]
    Input Text    address    ${roww}[Address]

Preview the robot
    Click Button    preview
    Wait Until Element Is Visible    robot-preview

Submit the order
    Click Button    order
    Page Should Contain Element    receipt

Store the receipt as a PDF
    [Arguments]    ${order_id}
    Set Local Variable    ${receipt_filename}    ${receipt_dir}receipt_${order_id}.pdf
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    content=${receipt_html}    output_path=${receipt_filename}
    RETURN    ${receipt_filename}

Take a screenshot of the robot
    [Arguments]    ${order_id}
    Set Local Variable    ${sshot_filename}    ${sshot_dir}robot_${order_id}
    Screenshot    id:robot-preview    ${sshot_filename}
    RETURN    ${sshot_filename}

Embed the robot screenshot to the reciept pdf file
    [Arguments]    ${sshot}    ${receipt}
    @{myfiles}=    Create List    ${sshot}:x=0,y=0
    Add Files To Pdf    ${myfiles}    ${receipt}    ${True}

Go to another robot
    Wait Until Keyword Succeeds    10x    1s    Click Button When Visible    order-another

Close the annoying modal
    Click Button    OK

Create zip file with receipts
    ${name}=    Get Value From User    Give name for Zip folder
    Create the ZIP    ${name}

Create the ZIP
    [Arguments]    ${name}
    Archive Folder With Zip    ${receipt_dir}    ${zip_dir}${name}

Delete screenshots and receipts
    Empty Directory    ${sshot_dir}
    Empty Directory    ${receipt_dir}

Close the Browser
    Close Browser

Minimal task
    Log    Done.
