pageextension 92155 Fijacion extends "Ficha Orden Fijacion"
{
    layout
    {

        addafter("Imagenes Orden fijación")
        {
            part("Qrs"; "Imagenes Orden fijacion")
            {
                Caption = 'Qr''s';
                ApplicationArea = All;
                SubPageLink = "Nº Orden" = field("Nº Orden"), "Valla Fijada" = const(false), "Es Qr" = const(true);
            }
            part("Correos"; "Sent Emails List Part")

            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }
    actions
    {
        addlast(Processing)
        {
            action("Crear Tarea")
            {
                Image = TaskPage;
                ApplicationArea = All;
                Caption = 'Crear Tarea';
                trigger OnAction()
                var
                    TipoOrden: Label 'Vallas,Opis,Otros';
                    rDet: Record "Orden fijación";
                    Cab: Record "Cab Orden fijación";
                    Resource: Record "Resource";
                    Opcion: Option " ",Valla,Opi,Otros;
                    Usertask: Record "User Task";
                    Proyecto: Record "Job";
                    TipoIncidencia: Record "User Task Group";
                    Gtask: Codeunit "Gtask";
                    TM: Record "Tenant Media";
                    DoccAttach: Record "Document Attachment";
                    DoccAttachTask: Record "Document Attachment";
                    DoccAttach2: Record "Document Attachment";
                    Outstr: OutStream;
                    RecRef: RecordRef;
                    InStr: InStream;
                    Imagenes: Record "Imagenes Orden fijación";
                    Det: Record "Orden fijación";
                    DetTemp: Record "Orden fijación" temporary;
                    im: Record "Imagenes Orden fijación";
                    Rep: Report "Etiqueta orden fijacion Opis";
                    Rep2: Report "Etiqueta fijacion soportes";
                    TempBlob: Codeunit "Temp Blob";
                    User: Record User;
                    EmailResponsable: Text;
                    EmailSupervisor: Text;
                    UserSetups: Record UsuariosGtask;
                    Responsable: Guid;
                    Supervisor: Guid;
                    ListaCorreos: Text;
                    Id: Integer;
                    UserTaskNew: Record "User Task";
                    Observaciones: Text;
                begin
                    UserSetups.ChangeCompany('Malla Publicidad');
                    DoccAttach.SetRange("Table ID", Database::"User Task");
                    DoccAttach.SetRange("No.", Format(Rec."Nº Orden"));
                    DoccAttach.DeleteAll();
                    Usertask.SetRange(OrdenFijacion, Rec."Nº Orden");
                    If Usertask.FindFirst() then
                        Error('Ya existe una tarea para esta orden');
                    UserSetups.SetRange(Departamento, 'TALLER');
                    UserSetups.FindFirst();
                    rDet.Setrange("Nº Orden", Rec."Nº Orden");
                    Opcion := Opcion::" ";
                    if Rec."Tipo soporte" = Rec."Tipo soporte"::Valla then Opcion := Opcion::Valla;
                    if Rec."Tipo soporte" = Rec."Tipo soporte"::OPI then Opcion := Opcion::Opi;
                    if Rec."Tipo soporte" = Rec."Tipo soporte"::Otros then Opcion := Opcion::Otros;
                    If (rDet.FindFirst()) and (Opcion = Opcion::" ") then begin
                        if rDet.Empresa <> '' then Resource.ChangeCompany(rDet.Empresa);
                        Resource.Get(rDet."Nº Recurso");
                        Opcion := Opcion::" ";
                        If Resource."Tipo Recurso" in ['VALLA', 'VALLAS', 'P.PEATOAL'] then
                            Opcion := Opcion::Valla;
                        if Resource."Tipo Recurso" in ['OPI', 'OPIS', 'LUM1,5X1,1', 'OPI ROT.', 'PLANIMETRO', 'RELOJ'] then
                            Opcion := Opcion::Opi;
                        if Resource."Tipo Recurso" in ['INDICADOR', 'VPEATON', 'MEDIANERA'] then
                            Opcion := Opcion::Otros;
                    end;
                    if Opcion = Opcion::" " then
                        Opcion := StrMenu(TipoOrden, Opcion, 'Seleccione el tipo de tarea a crear');
                    Usertask.Init();
                    if rDet.Empresa <> '' then Proyecto.ChangeCompany(rDet.Empresa);
                    Proyecto.Get(rDet."Nº proyecto");
                    if Proyecto."Nombre Comercial" = Proyecto."Bill-to Name" then Proyecto."Nombre Comercial" := '';
                    UserTask.Validate(Title, Proyecto.Description);
                    UserTask.SetDescription('Fijación soportes ' + Rec."Nº proyecto" + ' del cliente ' + Proyecto."Bill-to Name" + ' ' + Proyecto."Nombre Comercial");
                    UserTask."Created By" := UserSecurityId();
                    UserTask.Validate("Created DateTime", CurrentDateTime);
                    Usertask."Start DateTime" := CreateDateTime(Rec."Fecha fijación", 080000T);
                    Usertask."Due DateTime" := CreateDateTime(Rec."Fecha fijación", 130000T);
                    if not TipoIncidencia.Get('FIJACION') then begin
                        TipoIncidencia.Init();
                        TipoIncidencia."Code" := 'FIJACION';
                        TipoIncidencia."Description" := 'Fijación';
                        TipoIncidencia.Insert();

                    end;
                    If Rec."Material Fijación" <> "Material de Fijación"::"Sin Especificar" then begin
                        TipoIncidencia.SetRange("Material Fijación", Rec."Material Fijación");
                        if not TipoIncidencia.FindFirst() then begin
                            TipoIncidencia.Init();

                            Case Rec."Material Fijación" Of
                                "Material de Fijación"::Lona:
                                    begin
                                        TipoIncidencia."Description" := 'Fijación Lona';
                                        TipoIncidencia."Code" := 'FIJA_LONA';
                                    END;
                                "Material de Fijación"::Papel:
                                    begin
                                        TipoIncidencia."Description" := 'Fijación Papel';
                                        TipoIncidencia."Code" := 'FIJA_PAPEL';
                                    END;
                                "Material de Fijación"::Vinilo:
                                    begin
                                        TipoIncidencia."Description" := 'Fijación Vinilo';
                                        TipoIncidencia."Code" := 'FIJA_VINILO';
                                    END;
                                "Material de Fijación"::"Vinilo y lona":
                                    begin
                                        TipoIncidencia."Description" := 'Fijación Vinilo';
                                        TipoIncidencia."Code" := 'FIJA_VINILO';
                                    END;
                                "Material de Fijación"::"Vinilo y papel":
                                    begin
                                        TipoIncidencia."Description" := 'Fijación Vinilo';
                                        TipoIncidencia."Code" := 'FIJA_VINILO';
                                    END;

                            End;
                            TipoIncidencia.Insert();
                        end;

                    end else begin
                        If Rec."Tipo soporte" = Rec."Tipo soporte"::OPI then begin
                            TipoIncidencia.SetRange("Code", 'FIJA_OPIS');
                            If Not TipoIncidencia.FindFirst() then begin
                                TipoIncidencia.Init();
                                TipoIncidencia."Code" := 'FIJA_OPIS';
                                TipoIncidencia."Description" := 'Fijación Opis';
                                TipoIncidencia.Insert();
                            end;
                        end;
                        If Rec."Tipo soporte" = Rec."Tipo soporte"::OTROS then begin
                            TipoIncidencia.SetRange("Code", 'FIJA_OTROS');
                            If Not TipoIncidencia.FindFirst() then begin
                                TipoIncidencia.Init();
                                TipoIncidencia."Code" := 'FIJA_OTROS';
                                TipoIncidencia."Description" := 'Fijación Otros';
                                TipoIncidencia.Insert();
                            end;
                        end;
                    end;
                    Gtask.DevuelveSupervisoryResponsable(Responsable, Supervisor, 'TALLER', 'TALLER', TipoIncidencia.Code, EmailResponsable, EmailSupervisor, User, UserTask, ListaCorreos);
                    UserSetups.Reset();
                    //UserTask.Validate("User Task Group Assigned To", 'FIJACION');
                    UserTask.Validate(Priority, Usertask.Priority::High);
                    UserTask.Validate("Object Type", Usertask."Object Type"::Page);
                    UserTask.Validate("Object ID", Page::"Ficha Orden Fijacion");
                    UserTask.Validate("Due DateTime", CreateDateTime(Rec."Fecha fijación", 080000T));
                    Usertask."Start DateTime" := CreateDateTime(Rec."Fecha fijación", 080000T);
                    Usertask."Due DateTime" := CreateDateTime(Rec."Fecha fijación", 130000T);
                    Usertask.Id_record := Rec.RecordId;
                    Usertask.OrdenFijacion := Rec."Nº Orden";
                    UserTask.Insert(true);
                    Usertask."No." := Format(Usertask.ID);
                    UserTask."Supervisor" := Supervisor;
                    UserTask."User Task Group Assigned To" := TipoIncidencia."Code";
                    UserTask."No." := Format(UserTask.ID);
                    // If not IsNullGuid(UserTask.Supervisor) then
                    //     UserTask."Created By" := Usertask.Supervisor;
                    Usertask.OrdenFijacion := Rec."Nº Orden";
                    Usertask.Departamento := 'TALLER';
                    Usertask.Servicio := 'TALLER';
                    Usertask."Job No." := Rec."Nº Proyecto";
                    Usertask.Modify();
                    DoccAttach2.SetRange("Table ID", Database::"Cab Orden fijación");
                    DoccAttach2.SetRange("Line No.", Rec."Nº Orden");
                    If DoccAttach2.FindFirst() then
                        repeat
                            DoccAttach := DoccAttach2;
                            DoccAttach."Table ID" := Database::"User Task";
                            DoccAttach."No." := Format(Rec."Nº Orden");
                            DoccAttach."Line No." := 0;
                            If DoccAttach.Insert() Then;
                        until DoccAttach2.Next() = 0;
                    //Inserto los report
                    If Opcion = Opcion::Valla then begin
                        DoccAttach.Init();
                        DoccAttach."Table ID" := Database::"User Task";
                        DoccAttach."No." := Format(Rec."Nº Orden");

                        TM.Init();
                        TM.ID := CreateGuid();
                        TM.Description := StrSubstNo('Signature %1', format(CurrentDateTime));
                        TM."Mime Type" := 'Pdf/pdf';
                        TM."Company Name" := COMPANYNAME;
                        TM."File Name" := TM.Description + '.pdf';
                        TM.Height := 250;
                        TM.Width := 250;
                        TM.CalcFields(Content);
                        TM.Content.CreateOutStream(Outstr);
                        Cab.SetRange("Nº Orden", Rec."Nº Orden");
                        RecRef.GetTable(Cab);
                        Report.SaveAs(Report::"Etiqueta orden fijacion Vallas", '', ReportFormat::Pdf, Outstr, RecRef);
                        RecRef.Close();
                        Clear(RecRef);
                        RecRef.GetTable(Usertask);
                        RecRef.Get(Usertask.RecordId);
                        TM.Insert();
                        tm.CalcFields(Content);
                        Tm.Content.CreateInStream(InStr);
                        DoccAttach.SaveAttachmentFromStream(InStr, RecRef, Format(Rec."Nº Orden") + '.pdf');
                        Det.Reset();
                        Det.SetRange("Nº Orden", Rec."Nº Orden");
                        If Det.FindFirst() Then
                            repeat
                                DetTemp := Det;
                                DetTemp.Insert;
                            until Det.Next() = 0;
                        Det.DeleteAll();
                        if DetTemp.FindFirst() then
                            repeat
                                Det.DeleteAll();
                                Det := DetTemp;
                                Det.Insert;
                                Clear(TempBlob);
                                Clear(Outstr);
                                Clear(RecRef);
                                TempBlob.CreateOutStream(Outstr);
                                RecRef.GetTable(Cab);
                                Clear(Rep2);
                                Observaciones := Rec.GetWorkDescription();
                                Rep2.CargaObservaciones(Observaciones, Rec."Título");
                                Rep2.SetTableView(Rec);
                                Rep2.SaveAs('', ReportFormat::Pdf, Outstr, RecRef);
                                //Report.SaveAs(Report::"Etiqueta orden fijacion Vallas", '', ReportFormat::Pdf, Outstr, RecRef);
                                RecRef.Close();
                                Clear(RecRef);
                                RecRef.GetTable(Usertask);
                                RecRef.Get(Usertask.RecordId);
                                TempBlob.CreateInStream(InStr);
                                DoccAttach.Init();
                                DoccAttach."Table ID" := Database::"User Task";
                                DoccAttach."No." := Format(Rec."Nº Orden");
                                DoccAttach."Line No." := Det."Nº Reserva";
                                DoccAttach.SaveAttachmentFromStream(InStr, RecRef, Format(Rec."Nº Orden") + '-' + Format(DetTemp."Nº Reserva") + '.pdf');
                            Until DetTemp.Next() = 0;
                        Det.DeleteAll();
                        DetTemp.Reset();
                        if DetTemp.FindFirst() then
                            repeat
                                Det := DetTemp;
                                Det.Insert;
                            Until DetTemp.Next() = 0;
                        //DoccAttach.Insert();
                        tm.Delete();
                    end;
                    if Opcion = Opcion::Opi then begin
                        DoccAttach.Init();
                        DoccAttach."Table ID" := Database::"User Task";
                        DoccAttach."No." := Format(Rec."Nº Orden");
                        DoccAttach."Line No." := 0;
                        Imagenes.SetRange("Nº Orden", Rec."Nº Orden");
                        Imagenes.SetRange("Es Qr", false);
                        If Imagenes.FindSet() then
                            repeat
                                im.SetRange("Nº Orden", Imagenes."Nº Orden");
                                im.SetRange("Nº Imagen", Imagenes."Nº Imagen");
                                clear(rep);
                                Rep.Filtra(Imagenes."Nº Orden", Imagenes."Nº Imagen");
                                rep.SetTableView(im);
                                DoccAttach.Init();
                                DoccAttach."Table ID" := Database::"User Task";
                                DoccAttach."No." := Format(Rec."Nº Orden");
                                DoccAttach."Line No." := 0;
                                Clear(TM);

                                TM.Init();
                                TM.ID := CreateGuid();
                                TM.Description := StrSubstNo('Signature %1', format(CurrentDateTime));
                                TM."Mime Type" := 'Pdf/pdf';
                                TM."Company Name" := COMPANYNAME;
                                TM."File Name" := TM.Description + '.pdf';
                                TM.Height := 250;
                                TM.Width := 250;
                                TM.CalcFields(Content);
                                TM.Content.CreateOutStream(Outstr);
                                Clear(RecRef);
                                RecRef.GetTable(Imagenes);
                                Rep.SaveAs('', ReportFormat::Pdf, Outstr, RecRef);
                                TM.Insert();
                                tm.CalcFields(Content);
                                Tm.Content.CreateInStream(InStr);
                                Clear(RecRef);
                                RecRef.GetTable(Usertask);
                                RecRef.Get(Usertask.RecordId);
                                DoccAttach.SaveAttachmentFromStream(InStr, RecRef, Format(Rec."Nº Orden") + '.pdf');
                                //DoccAttach.Insert();
                                RecRef.Close();
                                tm.Delete();
                            until Imagenes.NEXT = 0;
                        Det.Reset();
                        Det.SetRange("Nº Orden", Rec."Nº Orden");
                        If Det.FindFirst() Then
                            repeat
                                DetTemp := Det;
                                DetTemp.Insert;
                            until Det.Next() = 0;
                        Det.DeleteAll();
                        if DetTemp.FindFirst() then
                            repeat
                                Det.DeleteAll();
                                Det := DetTemp;
                                Det.Insert;
                                Clear(TempBlob);
                                Clear(Outstr);
                                Clear(RecRef);
                                TempBlob.CreateOutStream(Outstr);
                                Clear(Rep);
                                Observaciones := Rec.GetWorkDescription();
                                Imagenes.SetRange("Nº Orden", Rec."Nº Orden");
                                Imagenes.SetRange("Es Qr", false);

                                RecRef.GetTable(Imagenes);
                                im.SetRange("Nº Orden", DetTemp."Nº Orden");
                                im.SetRange("Nº Imagen", DetTemp."Nº Imagen");
                                Rep.SetTableView(im);
                                Rep.Filtra(DetTemp."Nº Orden", DetTemp."Nº Imagen");
                                Rep.SaveAs('', ReportFormat::Pdf, Outstr, RecRef);
                                //Report.SaveAs(Report::"Etiqueta orden fijacion Vallas", '', ReportFormat::Pdf, Outstr, RecRef);
                                RecRef.Close();
                                Clear(RecRef);
                                RecRef.GetTable(Usertask);
                                RecRef.Get(Usertask.RecordId);
                                TempBlob.CreateInStream(InStr);
                                DoccAttach.Init();
                                DoccAttach."Table ID" := Database::"User Task";
                                DoccAttach."No." := Format(Rec."Nº Orden");
                                DoccAttach."Line No." := Det."Nº Reserva";
                                DoccAttach.SaveAttachmentFromStream(InStr, RecRef, Format(Rec."Nº Orden") + '-' + Format(DetTemp."Nº Reserva") + '.pdf');
                            Until DetTemp.Next() = 0;
                        Det.DeleteAll();
                        DetTemp.Reset();
                        if DetTemp.FindFirst() then
                            repeat
                                Det := DetTemp;
                                Det.Insert;
                            Until DetTemp.Next() = 0;
                        //DoccAttach.Insert();
                        //tm.Delete();

                    end;
                    if Opcion = Opcion::Otros then begin
                        DoccAttach.Init();
                        DoccAttach."Table ID" := Database::"User Task";
                        DoccAttach."No." := Format(Rec."Nº Orden");
                        DoccAttach."Line No." := 0;
                        Clear(TM);
                        TM.Init();
                        TM.ID := CreateGuid();
                        TM.Description := StrSubstNo('Signature %1', format(CurrentDateTime));
                        TM."Mime Type" := 'Pdf/pdf';
                        TM."Company Name" := COMPANYNAME;
                        TM."File Name" := TM.Description + '.pdf';
                        TM.Height := 250;
                        TM.Width := 250;
                        TM.CalcFields(Content);
                        TM.Content.CreateOutStream(Outstr);
                        Clear(RecRef);
                        Cab.SetRange("Nº Orden", Rec."Nº Orden");
                        RecRef.GetTable(Cab);
                        if rDet.Empresa <> '' then Proyecto.ChangeCompany(rDet.Empresa);
                        Proyecto.GET(rDet."Nº Proyecto");
                        rDet.SETRANGE("Nº Orden", Rec."Nº Orden");
                        rDet.FindFirst();
                        if rDet.Empresa <> '' then Resource.ChangeCompany(rDet.Empresa);
                        Resource.GET(rDet."Nº Recurso");
                        Observaciones := Rec.GetWorkDescription();
                        Rep2.CargaObservaciones(Observaciones, Resource.Medidas + ' ' + Rec."Título");
                        Rep2.SetTableView(Cab);
                        Rep2.SaveAs('', ReportFormat::Pdf, Outstr, RecRef);
                        TM.Insert();
                        tm.CalcFields(Content);
                        Tm.Content.CreateInStream(InStr);
                        Clear(RecRef);
                        RecRef.GetTable(Usertask);
                        RecRef.Get(Usertask.RecordId);
                        DoccAttach.SaveAttachmentFromStream(InStr, RecRef, Format(Rec."Nº Orden") + '.pdf');
                        RecRef.Close();
                        Det.Reset();
                        Det.SetRange("Nº Orden", Rec."Nº Orden");
                        //DoccAttach.Insert();
                        If Det.FindFirst() Then
                            repeat
                                DetTemp := Det;
                                DetTemp.Insert;
                            until Det.Next() = 0;
                        Det.DeleteAll();
                        if DetTemp.FindFirst() then
                            repeat
                                Det.DeleteAll();
                                Det := DetTemp;
                                Det.Insert;
                                Clear(TempBlob);
                                Clear(Outstr);
                                Clear(RecRef);
                                TempBlob.CreateOutStream(Outstr);
                                Cab.SetRange("Nº Orden", Rec."Nº Orden");
                                RecRef.GetTable(Cab);
                                if rDet.Empresa <> '' then Resource.ChangeCompany(rDet.Empresa);
                                Resource.GET(rDet."Nº Recurso");
                                Clear(Rep2);
                                Observaciones := Rec.GetWorkDescription();
                                Rep2.CargaObservaciones(Observaciones, Resource.Medidas + ' ' + Rec."Título");
                                Rep2.SetTableView(Cab);
                                Rep2.SaveAs('', ReportFormat::Pdf, Outstr, RecRef);
                                RecRef.Close();
                                Clear(RecRef);
                                RecRef.GetTable(Usertask);
                                RecRef.Get(Usertask.RecordId);
                                TempBlob.CreateInStream(InStr);
                                DoccAttach.Init();
                                DoccAttach."Table ID" := Database::"User Task";
                                DoccAttach."No." := Format(Rec."Nº Orden");
                                DoccAttach."Line No." := Det."Nº Reserva";
                                DoccAttach.SaveAttachmentFromStream(InStr, RecRef, Format(Rec."Nº Orden") + '-' + Format(DetTemp."Nº Reserva") + '.pdf');
                            Until DetTemp.Next() = 0;
                        Det.DeleteAll();
                        DetTemp.Reset();
                        if DetTemp.FindFirst() then
                            repeat
                                Det := DetTemp;
                                Det.Insert;
                            Until DetTemp.Next() = 0;
                        //DoccAttach.Insert();
                        tm.Delete();
                    end;
                    Commit();
                    Page.RunModal(Page::"User Task Card", UserTask);
                    iF UserTask.Estado = UserTask.Estado::Cancelado then begin
                        UserTask.Get(UserTask.ID);
                        Commit();
                        If Confirm('¿Desea borrar la tarea?') then begin
                            UserTask.Delete();
                            exit;
                        end;
                    end;

                    Commit();
                    UserTask.Get(UserTask.ID);
                    Id := UserTask.ID;
                    //If Opcion <> Opcion::Opi Then begin
                    DoccAttach.Reset();
                    rDet.Reset;
                    DoccAttach.SetRange("Table ID", Database::"User Task");
                    DoccAttach.SetRange("No.", Usertask."No.");
                    DoccAttach.SetFilter("Line No.", '<>%1', 0);
                    Message('Se generarán %1 tareas de fijación', DoccAttach.Count);
                    If DoccAttach.FindFirst() then
                        repeat
                            rDet.SetRange("Nº Orden", Rec."Nº Orden");
                            rDet.SetRange("Nº Reserva", DoccAttach."Line No.");
                            If Not rDet.FindFirst() then rDet.Init;
                            if rDet.Empresa <> '' then Resource.ChangeCompany(rDet.Empresa);
                            If not Resource.Get(rDet."Nº Recurso") then Resource.iNit();
                            UserTaskNew.FindLast();
                            Id := UserTaskNew.ID + 1;
                            UserTaskNew := Usertask;
                            UsertaskNew.Id := Id;
                            UserTaskNew.Insert();
                            If Opcion = Opcion::Opi then begin
                                UserTaskNew.fastPhoto := true;
                                UserTaskNew.Resource := Resource."No.";
                            end;
                            UserTaskNew.Get(ID);
                            UserTaskNew.Title := Copystr('Fijación ' + Resource.Name + ' ' + Usertask.Title, 1, MaxStrLen(UserTaskNew.Title));
                            UserTaskNew.SetDescription('Fijación ' + Resource.Name + ' nº ' + Resource."No." + ' del proyecto ' + Rec."Nº proyecto" + ' del cliente ' + Proyecto."Bill-to Name" + ' ' + Proyecto."Nombre Comercial");
                            Usertasknew.Reserva := DoccAttach."Line No.";
                            UserTaskNew."No." := Format(UsertaskNew.ID);
                            UserTaskNew.Estado := UserTask.Estado::Pendiente;
                            UserTaskNew.Modify();
                            Clear(Gtask);
                            DoccAttachTask := DoccAttach;
                            DoccAttachTask."No." := UsertaskNew."No.";
                            DoccAttachTask.Insert();
                        //Generar Una vez Revisadas las tareas
                        //Gtask.CrearTareaFijacion(Rec, UsertaskNew);
                        until DoccAttach.Next() = 0;
                    Commit();
                    UserTaskNew.SetRange(OrdenFijacion, Rec."Nº Orden");
                    UserTaskNew.SetFilter(Reserva, '<>%1', 0);
                    Message('Se han generado %1 tareas de fijación', DoccAttach.Count);
                    Page.RunModal(Page::"User Task List", UsertaskNew);
                    If UserTaskNew.FindFirst() Then
                        repeat
                            Gtask.CrearTareaFijacion(Rec, UsertaskNew, Opcion);
                        until UserTaskNew.Next() = 0;

                    // end else begin
                    //     Clear(Gtask);
                    //     Gtask.CrearTareaFijacion(Rec, Usertask);
                    // end;
                    DoccAttach.Reset();
                    DoccAttach.SetRange("Table ID", Database::"User Task");
                    DoccAttach.SetRange("No.", Usertask."No.");
                    DoccAttach.SetFilter("Line No.", '<>%1', 0);
                    //If Opcion <> Opcion::Opi then
                    DoccAttach.DeleteAll(true);
                    DoccAttach.Reset();
                    Gtask.Email(UserTask, EmailResponsable, EmailSupervisor);
                    EnviaCorreo(Usertask, true, '', false, 'Tarea Fijación', EmailResponsable, EmailSupervisor, ListaCorreos, 'julian@malla.es;andreuserra@malla.es;lllompart@malla.es', User."Full Name");
                    //If Opcion <> 2 then 
                    Usertask.Delete();
                end;
            }
            action("Ver Tareas")
            {
                Image = "Task";
                ApplicationArea = All;
                Caption = 'Ver Tareas';
                trigger OnAction()
                var

                    Usertask: Record "User Task";

                begin
                    Usertask.SetRange(OrdenFijacion, Rec."Nº Orden");
                    If Not Usertask.FindFirst() then
                        Error('No existe una tarea para esta orden')
                    else
                        Page.RunModal(Page::"User Task List", Usertask);
                    iF UserTask.Estado = UserTask.Estado::Cancelado then begin
                        Commit();
                        Usertask.Get(Usertask.ID);
                        UserTask.Delete(true);
                        exit;
                    end;
                    Commit()

                end;
            }
            action("Borrar Tarea")
            {
                Image = "Delete";
                ApplicationArea = All;
                Caption = 'Borrar Tarea';
                trigger OnAction()
                var
                    Gtask: Codeunit Gtask;
                    Usertask: Record "User Task";
                begin
                    Usertask.SetRange(OrdenFijacion, Rec."Nº Orden");
                    If Usertask.FindFirst() then begin
                        Gtask.DeleteTarea(Usertask.Id_Tarea);
                        Usertask.Delete();

                    end;
                end;
            }
            action(ReenviarCorreo)
            {
                Image = "Email";
                ApplicationArea = All;
                Caption = 'Reenviar Correo';
                trigger OnAction()
                var
                    Usertask: Record "User Task";
                    Gtask: Codeunit Gtask;
                    Responsable: Text;
                    Supervisor: Text;
                    EmailResponsable: Text;
                    EmailSupervisor: Text;
                    ListaCorreos: Text;
                    User: Record User;
                begin
                    Usertask.SetRange(OrdenFijacion, Rec."Nº Orden");
                    If Usertask.FindFirst() then begin
                        Gtask.DevuelveSupervisoryResponsable(Usertask."Assigned To", Usertask.Supervisor, 'TALLER', 'TALLER', Usertask."User Task Group Assigned To", EmailResponsable, EmailSupervisor, User, Usertask, ListaCorreos);
                        EnviaCorreo(Usertask, true, '', false, 'Tarea Fijación', EmailResponsable, EmailSupervisor, ListaCorreos, 'julian@malla.es;lllompart@malla.es;andreuserra@malla.es', User."Full Name");
                    end;
                end;
            }
        }
        addafter(AsignarImagenaLineas)
        {
            actionref(CreartareaRef; "Crear Tarea") { }
            actionref(VertareaRef; "Ver Tareas") { }
        }
    }
    trigger OnOpenPage()
    var

    begin
        CurrPage.Correos.Page.SetRelatedRecord(Database::"User Task", Rec.SystemId);
        CurrPage.Correos.Page.Load();
        CurrPage.Correos.Page.Update(false);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.Correos.Page.SetRelatedRecord(Database::"User Task", Rec.SystemId);
        CurrPage.Correos.Page.Load();
        CurrPage.Correos.Page.Update(false);
    end;

    procedure EnviaCorreo(
       Var UserTask: Record "User Task";
       Adjunto: Boolean;
       Motivo: Text;
       Notificacion: Boolean;
       Asunto: Text;
       SendTo: Text;
       CC: Text;
       ListaCorreos: Text;
       BCC: Text; Nombre: Text)


    var
        Mail: Codeunit Mail;
        Body: Text;
        Customer: Record 18;
        BigText: Text;
        REmail: Record "Email Item" temporary;
        emilesc: Enum "Email Scenario";
        rInf: Record "Company Information";
        Funciones: Codeunit "Funciones Correo PDF";
        AttachmentStream: InStream;
        out: OutStream;
        Secuencia: Integer;
        ficheros: Record "Document Attachment";
        SalesHeader: Record "Sales Header";
        Recref: RecordRef;
        base64: Text;
        Cbase64: Codeunit "Base64 Convert";
        OutStream: OutStream;
        Tempblob: Codeunit "Temp Blob";
    begin
        rInf.Get();

        If Notificacion Then begin
            BigText := Motivo;
        end else begin
            //Andres Serra Candela
            If StrPos(Nombre, ' ') > 0 then
                Nombre := CopyStr(Nombre, 1, Strpos(Nombre, ' ') - 1);
            if Time < 140000T then
                BigText := ('Buenos días ' + Nombre + ':')
            else if Time < 200000T then
                BigText := ('Buenas tardes ' + Nombre + ':')
            else
                BigText := ('Buenas noches ' + Nombre + ':');
            //BigText := ('Estimado:');
            BigText := BigText + '<br> </br>';
            BigText := BigText + '<br> </br>';
            BigText := BigText + ('Se ha generado la Tarea: <b>' + UserTask.GetDescription() + ' </b> ');
            //BigText := BigText + (', ha cambiado de estado a: <b>' + Format(Estado) + ' .</b>');
            if Motivo <> '' then
                BigText := BigText + ('<br> </br>' + 'Motivo: ' + Motivo);

            BigText := BigText + '<br> </br>';
        end;

        BigText := BigText + '<br> </br>';
        BigText := BigText + '<br> </br>';
        BigText := BigText + ('Aprovechamos la ocasión para enviarte un cordial saludo');
        BigText := BigText + '<br> </br>';
        BigText := BigText + '<br> </br>';
        BigText := BigText + ('Atentamente');
        BigText := BigText + '<br> </br>';
        BigText := BigText + ('Dpto. Medios');
        BigText := BigText + '<br> </br>';

        BigText := BigText + (rInf.Name);
        //"Plaintext Formatted":=TRUE;
        // SendMsg.AppendBody(BigText);
        // CLEAR(BigText);
        BigText := BigText + '<br> </br>';
        BigText := BigText + '<br> </br>';
        REmail.AddAttachment(Funciones.CargaPie(Base64), 'emailfoot.png');
        BigText := BigText + '<img src="data:image/png;base64,' + base64 + '" />';//"emailFoot.png" />';

        BigText := BigText + '<br> </br>';
        BigText := BigText + '<br> </br>';
        BigText := BigText + '<font face="Franklin Gothic Book" sice=2 color=#A6A6A6>';
        BigText := BigText + ('<b>SI NO DESEA RECIBIR MAS INFORMACION, CONTESTE ESTE E-MAIL INDICANDOLO EXPRESAMENTE</b>');
        BigText := BigText + '</font>';
        BigText := BigText + '<br> </br>';
        BigText := BigText + '<font face="Franklin Gothic Book" size=1 color=#A6A6A6>';
        BigText := BigText + ('En cumplimiento de lo establecido en el REGLAMENTO (UE) 2016/679, de 27 de abril de 2016, con plenos efectos desde el 25 de mayo de 2018, le recordamos que sus datos personales son');
        BigText := BigText + ('objeto de tratamiento por parte de MALLA S.A. Le informamos también que tiene la posibilidad de ejercer los derechos de acceso, rectificación, supresión, oposición, limitación del');
        BigText := BigText + (' tratamiento y portabilidad de sus datos, mediante comunicación escrita a la dirección de correo electrónico <a href="mailto:lopd@malla.es" rel="noreferrer" target="_blank" heap-ignore="true"><span style="color:blue">lopd@malla.es</span></a>, o bien, a nuestra dirección postal (' + rInf.Name + ')');
        BigText := BigText + (rInf.Address + '. ' + rInf."Post Code" + '. ' + rInf.City + '. España');
        BigText := BigText + '<br> </br>';
        BigText := BigText + ('Este correo y sus archivos asociados son privados y confidenciales y va dirigido exclusivamente a su destinatario. Si recibe este correo sin ser el destinatario del mismo, le rogamos proceda');
        BigText := BigText + (' a su eliminación y lo ponga en conocimiento del emisor. La difusión por cualquier medio del contenido de este correo podría ser sancionada conforme a lo previsto en las leyes españolas.');
        BigText := BigText + ('No se autoriza la utilización con fines comerciales o para su incorporación a ficheros automatizados de las direcciones del emisor o del destinatario');
        BigText := BigText + '</font>';
        //REmail.Subject := 'Pago contrato ' + NContrato;
        REmail.Subject := Asunto;
        REmail."Send To" := SendTo;
        if CC <> '' then
            REmail."Send CC" := CC;
        if ListaCorreos <> '' then
            if REmail."Send To" = '' then
                REmail."Send To" := ListaCorreos
            else
                REmail."Send To" := REmail."Send To" + ';' + ListaCorreos;
        if BCC <> '' then
            REmail."Send BCC" := BCC;
        REmail.SetBodyText(BigText);
        REmail."From Name" := UserId;
        If Adjunto then begin

            // If Contratostemp.FindFirst() then
            //     repeat
            ficheros.SetRange("Table ID", Database::"User Task");
            ficheros.SetRange("No.", UserTask."No.");
            If ficheros.FindLast() then
                repeat
                    base64 := ficheros.ToBase64StringOcr(ficheros.url);
                    Clear(Cbase64);
                    If UrlToBase64(Tempblob, base64, AttachmentStream) then begin
                        //si filename ya con tiene la extensión no poner extension
                        if StrPos(ficheros."File Name", '.' + ficheros."File Extension") > 0 then
                            REmail.AddAttachment(AttachmentStream, ficheros."File Name")
                        else
                            REmail.AddAttachment(AttachmentStream, ficheros."File Name" + '.' + ficheros."File Extension");
                    end;

                until ficheros.Next() = 0;
        end;
        REmail.AddSourceDocument(Database::"User Task", UserTask.SystemId);
        if REmail.Send(true, emilesc::Gtasks) then begin

        end;
    end;

    [TryFunction]
    procedure UrlToBase64(var TempBlob: Codeunit "Temp Blob"; var Base64: Text; Var InsTream: InStream)
    var
        OutStream: OutStream;
        Cbase64: Codeunit "Base64 Convert";
    begin
        Tempblob.CreateOutStream(OutStream);
        Cbase64.FromBase64(base64, OutStream);
        Tempblob.CreateInStream(InStream);


    end;
}

