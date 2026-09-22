report 50081 "Ordenes Trabajo"
{
    Caption = 'Orden de trabajo EMT';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultRenderingLayout = OrdenTrabajoRDLC;

    dataset
    {
        dataitem(Lineas; "Time Sheet Line")
        {
            RequestFilterFields = "Time Sheet No.";

            column(Linea_NumLinea; Lineas."Line No.")
            {
            }
            column(Linea_TimeSheetNo; Lineas."Time Sheet No.")
            {
            }
            column(Linea_TipoStd; Lineas.Type)
            {
            }
            column(Linea_JobNo; Lineas."Job No.")
            {
            }
            column(Linea_Description; Lineas.Description)
            {
            }
            column(Linea_TipoParte; Lineas.Tipo)
            {
            }
            column(Linea_No; Lineas.No)
            {
            }
            column(Linea_Descripcion; Lineas.Descripcion)
            {
            }
            column(Linea_Unidad; Lineas.Unidad)
            {
            }
            column(Linea_Cantidad; Lineas.Cantidad)
            {
            }
            column(Linea_Precio; Lineas.Precio)
            {
            }
            column(Linea_Dto; Lineas.Dto)
            {
            }
            column(Linea_Importe; Lineas.Importe)
            {
            }
            column(Linea_Finalizada; Lineas.Finalizada)
            {
            }
            column(Linea_Comprobada; Lineas.Comprobada)
            {
            }

            column(Cab_OrdenNo; Cab_OrdenNo)
            {
            }
            column(Cab_ClienteNo; Cab_ClienteNo)
            {
            }
            column(Cab_NombreCliente; Cab_NombreCliente)
            {
            }
            column(Cab_Direccion; Cab_Direccion)
            {
            }
            column(Cab_FechaIni; Cab_FechaIni)
            {
            }
            column(Cab_FechaFin; Cab_FechaFin)
            {
            }
            column(Cab_Estado; Cab_EstadoTxt)
            {
            }
            column(Cab_Proyecto; Cab_Proyecto)
            {
            }
            column(Cab_IdFactura; Cab_IdFactura)
            {
            }
            column(Pet_Numero; Pet_Numero)
            {
            }
            column(Pet_Descripcion; Pet_Descripcion)
            {
            }
            column(QrBase64; QrBase64)
            {
            }
            column(EmpresaNombre; NombreEmpresa)
            {
            }
            column(EmpresaPicture; CompanyInformation.Picture)
            {
            }
            column(EmpresaCabTexto; EmpresaCabTexto)
            {
            }

            trigger OnAfterGetRecord()
            var
                TSH: Record "Time Sheet Header";
                Pet: Record Incidencias;
            begin
                if not TSH.Get(Lineas."Time Sheet No.") then
                    CurrReport.Skip();
                if TSH.Tipo <> TSH.Tipo::EMT then
                    CurrReport.Skip();

                if UltimaCabeceraOrden <> Lineas."Time Sheet No." then begin
                    UltimaCabeceraOrden := Lineas."Time Sheet No.";
                    ClearCabeceraYPeticionVars();
                    Cab_OrdenNo := TSH."No.";
                    Cab_ClienteNo := TSH.Cliente;
                    Cab_NombreCliente := TSH."Nombre Cliente";
                    Cab_Direccion := TSH."Dirección";
                    Cab_FechaIni := TSH."Starting Date";
                    Cab_FechaFin := TSH."Ending Date";
                    Cab_EstadoTxt := Format(TSH.Estado);
                    Cab_Proyecto := TSH.Proyecto;
                    Cab_IdFactura := TSH."Id Factura";
                    QrBase64 := GenerarQrOrdenBase64(Cab_OrdenNo);

                    Pet.SetRange("Parte Trabajo", TSH."No.");
                    Pet.SetRange("Es Peticion", true);
                    if Pet.FindFirst() then begin
                        Pet_Numero := Pet."No.";
                        Pet_Descripcion := Pet."Descripción";
                    end;
                end;
            end;

            trigger OnPreDataItem()
            begin
                UltimaCabeceraOrden := '';
                ClearCabeceraYPeticionVars();
            end;
        }
    }

    rendering
    {
        layout(OrdenTrabajoRDLC)
        {
            Type = RDLC;
            Caption = 'Orden de trabajo EMT';
            LayoutFile = 'src/report/Layouts/Report50049.OrdenesTrabajo.rdlc';
        }
    }

    labels
    {
        LblTitle = 'Orden de trabajo';
        LblPeticion = 'Petición';
        LblOrden = 'Nº orden';
        LblCliente = 'Cliente';
        LblNombreCli = 'Nombre cliente';
        LblDireccion = 'Dirección';
        LblFIni = 'Fecha inicio';
        LblFFin = 'Fecha fin';
        LblEstado = 'Estado';
        LblProyecto = 'Proyecto';
        LblFactura = 'Factura';
        LblLineas = 'Líneas del parte';
    }

    trigger OnPreReport()
    begin
        LoadCompanyHeader();
    end;

    var
        CompanyInformation: Record "Company Information";
        FormatAddr: Codeunit "Format Address";
        CompanyAddr: array[8] of Text[100];
        NombreEmpresa: Text[100];
        EmpresaCabTexto: Text[2048];
        Cab_OrdenNo: Code[20];
        Cab_ClienteNo: Code[20];
        Cab_NombreCliente: Text[50];
        Cab_Direccion: Text[50];
        Cab_FechaIni: Date;
        Cab_FechaFin: Date;
        Cab_EstadoTxt: Text[30];
        Cab_Proyecto: Code[20];
        Cab_IdFactura: Code[20];
        Pet_Numero: Code[20];
        Pet_Descripcion: Text[100];
        QrBase64: Text;
        UltimaCabeceraOrden: Code[20];

    local procedure LoadCompanyHeader()
    begin
        CompanyInformation.Get();
        CompanyInformation.CalcFields(Picture);
        NombreEmpresa := CompanyInformation.Name;
        Clear(CompanyAddr);
        FormatAddr.Company(CompanyAddr, CompanyInformation);
        BuildEmpresaCabTexto();
    end;

    local procedure BuildEmpresaCabTexto()
    var
        i: Integer;
    begin
        Clear(EmpresaCabTexto);
        for i := 2 to 8 do
            AppendPipeLine(EmpresaCabTexto, CompanyAddr[i]);
        AppendPipeLine(EmpresaCabTexto, BuildEmpresaContactoLine());
        AppendPipeLine(EmpresaCabTexto, BuildEmpresaBancoLine());
    end;

    local procedure AppendPipeLine(var Dest: Text; Line: Text)
    begin
        if Line = '' then
            exit;
        if Dest <> '' then
            Dest += '|';
        Dest += Line;
    end;

    local procedure BuildEmpresaContactoLine(): Text
    var
        T: Text;
    begin
        if CompanyInformation."Phone No." <> '' then
            T := 'Tel. ' + CompanyInformation."Phone No.";
        if CompanyInformation."VAT Registration No." <> '' then begin
            if T <> '' then
                T += '   ·   ';
            T += 'CIF/NIF: ' + CompanyInformation."VAT Registration No.";
        end;
        if CompanyInformation."E-Mail" <> '' then begin
            if T <> '' then
                T += '   ·   ';
            T += CompanyInformation."E-Mail";
        end;
        if CompanyInformation."Home Page" <> '' then begin
            if T <> '' then
                T += '   ·   ';
            T += CompanyInformation."Home Page";
        end;
        exit(T);
    end;

    local procedure BuildEmpresaBancoLine(): Text
    begin
        if (CompanyInformation."Bank Name" = '') and (CompanyInformation."Bank Account No." = '') then
            exit('');
        if CompanyInformation."Bank Name" <> '' then
            exit('Banco: ' + CompanyInformation."Bank Name" + ' · Cuenta: ' + CompanyInformation."Bank Account No.");
        exit('Cuenta: ' + CompanyInformation."Bank Account No.");
    end;

    local procedure ClearCabeceraYPeticionVars()
    begin
        Clear(Cab_OrdenNo);
        Clear(Cab_ClienteNo);
        Clear(Cab_NombreCliente);
        Clear(Cab_Direccion);
        Clear(Cab_FechaIni);
        Clear(Cab_FechaFin);
        Clear(Cab_EstadoTxt);
        Clear(Cab_Proyecto);
        Clear(Cab_IdFactura);
        Clear(Pet_Numero);
        Clear(Pet_Descripcion);
        Clear(QrBase64);
    end;

    local procedure GenerarQrOrdenBase64(OrdenNo: Code[20]): Text
    var
        CompanyInfoPage: Page "Company Information";
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        InStr: InStream;
    begin
        if OrdenNo = '' then
            exit('');
        if not CompanyInfoPage.GenerateQRCodeImage('https://gtasks-app.deploy.malla.es/IdQr/OT-' + OrdenNo, TempBlob) then
            exit('');
        TempBlob.CreateInStream(InStr);
        exit(Base64Convert.ToBase64(InStr));
    end;
}
