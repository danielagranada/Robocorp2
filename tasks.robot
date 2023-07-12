*** Settings ***
Documentation       Robot creado para obtener la certificación de nivel 2.
...                 Ordenes de robots desde RobotSpareBin Industries INC
...                 Guarda el recibo html de la orden como un archivo pdf
...                 Guarda la captura de pantalla del robot
...                 Incrusta la captura de pantalla del robot en el recibo pdf
...                 Crea un archivo ZIP de los recibos y las imagenes

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.Tables
Library             RPA.PDF
Library    RPA.Archive


*** Tasks ***
recibos de ordenes de RobotSpareBin
    Abrir el sitio web de pedidos de robots
    Obtener ordenes
    Proceso de ordenes
    [Teardown]     cerrar navegador


*** Keywords ***
Abrir el sitio web de pedidos de robots
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Obtener ordenes
    Download    https://robotsparebinindustries.com/orders.csv    %{ROBOT_ROOT}${/}recibos.csv    overwrite=${TRUE}
    ${table}=    Read table from CSV    %{ROBOT_ROOT}${/}recibos.csv    head=${True}
    RETURN    ${table}

Proceso de ordenes
    ${orders}=    Obtener ordenes
    FOR    ${order}    IN    @{orders}
        Cierra el molesto modal
        Wait Until Keyword Succeeds    3x    5s    Completar formulario    ${order}
        ${pdf}=    Guardar recibo como archivo pdf    ${order}[Order number]
        ${screenshot}=    Tomar screenshot de la imagen del bot    ${order}[Order number]
        embeber imagen y pdf    ${pdf}    ${screenshot}
        Hacer otra orden
    END
    Crear ZIP
    

Cierra el molesto modal
    Sleep    2
    Click Button    OK

Completar formulario
    [Arguments]    ${orders}
    Select From List By Value    head    ${orders}[Head]
    Select Radio Button    body    ${orders}[Body]
    Input Text    class:form-control    ${orders}[Legs]
    Input Text    address    ${orders}[Address]
    Click Button    preview
    Wait Until Keyword Succeeds    2min    500ms    Submit Form

Submit Form
    Click Button    order
    Page Should Contain Element  receipt

Guardar recibo como archivo pdf
    [Arguments]    ${name}
    ${order_results_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${order_results_html}    ${OUTPUT_DIR}${/}${name}.pdf
    RETURN    ${OUTPUT_DIR}${/}${name}.pdf
    Wait Until Element Is Visible    id:receipt
    Sleep    2

Tomar screenshot de la imagen del bot
    [Arguments]    ${name}
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}${name}.png
    RETURN    ${OUTPUT_DIR}${/}${name}.png

embeber imagen y pdf
    [Arguments]    ${pdf}    ${screenshot}
    ${pdf_orden}=    Open Pdf    ${pdf}
    ${files}=    Create List    ${pdf}    ${screenshot}
    Add Files To Pdf    ${files}    ${pdf}
    Close Pdf    ${pdf_orden}

Hacer otra orden
    Click Button    order-another

Crear ZIP
    
    ${zip_file}=     Set Variable  ${OUTPUT_DIR}${/}pdfs.zip
    Archive Folder With Zip    ${OUTPUT_DIR}${/}    ${zip_file}

 cerrar navegador
     Close Browser