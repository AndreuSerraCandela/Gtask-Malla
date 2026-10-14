/// <summary>
/// TableExtension Tareasusuarios (ID 90103) extends Record User Task.
/// </summary>
tableextension 92103 Tareasusuarios extends "User Task"
{
    fields
    {
        field(50000; Id_Tarea; Text[250])
        {
            Caption = 'Id_tarea';
            DataClassification = ToBeClassified;
        }
        field(50001; Supervisor; guid)
        {
            Caption = 'Supervisor';
            DataClassification = ToBeClassified;
            TableRelation = User."User Security ID";//WHERE("License Type" = CONST("Full User"));
            ValidateTableRelation = false;
            trigger OnLookup()
            var
                User: Record UsuariosGtask;
            begin
                User.ChangeCompany('Malla Publicidad');
                If Page.RunModal(Page::UsuariosGtask, User) = Action::LookupOK then
                    Supervisor := user."Id Usuario";
            end;

        }

        field(50015; "Supervisor User Name"; Code[50])
        {
            CalcFormula = lookup(User."User Name" where("User Security ID" = field("Supervisor")));
            Caption = 'Nombre Supervisor';
            Editable = false;
            FieldClass = FlowField;
        }
        field(50002; "No."; Code[20])
        {

        }
        field(50003; "Line No."; Integer)
        {

        }
        field(50012; Id_record; RecordId)
        {

        }
        field(50004; OrdenFijacion; Integer)
        {
            Caption = 'Orden Fijación';
            trigger OnValidate()
            var
                RecOrdenFijacion: Record "Orden fijación";
            begin
                RecOrdenFijacion.SetRange("Nº Orden", OrdenFijacion);
                if RecOrdenFijacion.FindFirst() then begin
                    "Job No." := RecOrdenFijacion."Nº Proyecto";
                end;

            end;
        }
        field(50005; "Job No."; Code[20])
        {
            TableRelation = Job."No.";
        }
        //departamento
        field(50006; Departamento; Text[20])
        {
            Caption = 'Departamento';
            DataClassification = ToBeClassified;
            TableRelation = "Responsibility Center"."Code";
        }
        //servicio
        field(50007; Servicio; Text[20])
        {
            Caption = 'Servicio';
            DataClassification = ToBeClassified;
            TableRelation = "Work Center"."No.";
        }
        field(50013; Reserva; Integer) { }

        modify("Assigned To")
        {
            TableRelation = User."User Security ID";//WHERE("License Type" = CONST("Full User"));


        }
        modify("User Task Group Assigned To")
        {
            Caption = 'Categoría';

        }
        field(50008; Categoría; Code[20])
        {
            Caption = 'User Task Group Assigned To';
            DataClassification = CustomerContent;
            TableRelation = "User Task Group".Code;

            trigger OnValidate()
            var
                Categorias: Record "User Task Group Member";
                Procesos_GTask: Codeunit Procesos_GTask;
            begin
                Categorias.ChangeCompany('Malla Publicidad');
                "User Task Group Assigned To" := Categoría;
                Categorias.SetRange("User Task Group Code", Categoría);
                Categorias.SetRange(Departamento, Departamento);
                Categorias.SetRange(Responsable, true);
                if Categorias.FindFirst() then
                    "Assigned To" := Categorias."User Security ID";
                "User Task Group Assigned To" := "Categoría";
                Procesos_GTask.ActualizarGrupoTarea(Rec, false);
            end;
        }
        field(50009; Estado; Enum "Task Enum")
        {
            Caption = 'Estado';
            DataClassification = ToBeClassified;
        }
        field(50010; "Fecha Comunicado Cambio"; DateTime)
        {
            Caption = 'Fecha Comunicado Cambio';
            DataClassification = ToBeClassified;
        }
        field(50011; "Fecha Cambio"; DateTime)
        {
            Caption = 'Fecha Cambio';
            DataClassification = ToBeClassified;
        }
        field(50014; Mentioned; BLOB)
        {
            Caption = 'Mencionados';
            SubType = Memo;
        }
        field(50016; fastPhoto; Boolean)
        {
            Caption = 'Foto rápida';
            DataClassification = ToBeClassified;
        }
        field(50017; Resource; Code[20])
        {
            Caption = 'Recurso';
            DataClassification = ToBeClassified;
        }
        field(50018; IdQr; Text[100])
        { }
        field(50019; OrdenRetirada; Boolean)
        {
            Caption = 'Orden Fijación';
        }
        field(50020; Frecuencia; DateFormula)
        {
            ObsoleteState = Removed;

        }
        field(50021; DependenciaCreada; Boolean)
        {
            Caption = 'Dependencia Creada';
        }
        field(50022; ZonaLimpieza; Integer)
        {
            Caption = 'Zona Limpieza';
            DataClassification = ToBeClassified;
            TableRelation = "Zonas Limpieza".Id;
        }
        field(50023; TipoTarea; Text[50])
        {
            Caption = 'Emplazamiento';
            DataClassification = ToBeClassified;
            TableRelation = Emplazamientos."Nº Emplazamiento";
        }
        field(50024; TareaAnterior; Integer)
        {
            Caption = 'Tarea Anterior';
            DataClassification = ToBeClassified;
        }
        field(50025; EsPeriodica; Boolean)
        {
            Caption = 'Es Periodica';
            DataClassification = ToBeClassified;
        }
        //Crear Parte de Trabajo
        field(50026; CrearParte; Boolean)
        {
            Caption = 'Crear Parte de Trabajo';
            DataClassification = ToBeClassified;
        }
        //Empresa Linea
        field(50027; EmpresaTarea; Text[30])
        {
            Caption = 'Empresa Linea';
            DataClassification = ToBeClassified;
        }
        field(50028; RecurrenciaActiva; Boolean)
        {
            Caption = 'Recurrencia activa';
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                if not RecurrenciaActiva then
                    ActualizarTextoRecurrencia();
            end;
        }
        field(50029; FormulaRecurrencia; DateFormula)
        {
            Caption = 'Fórmula recurrencia';
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                ActualizarTextoRecurrencia();
            end;
        }
        field(50030; TextoRecurrencia; Text[250])
        {
            Caption = 'Recurrencia configurada';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(50031; RecurrenciaFin; Date)
        {
            Caption = 'Recurrencia hasta';
            DataClassification = ToBeClassified;
        }
        field(50032; TareaRecurrenteOrigen; Integer)
        {
            Caption = 'Tarea origen recurrencia';
            DataClassification = ToBeClassified;
            Editable = false;
            TableRelation = "User Task".ID;
        }
        field(50033; Avisar; Boolean)
        {
            Caption = 'Avisar por correo';
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                if Avisar then
                    ActualizarFechaAviso()
                else begin
                    Clear(FechaAviso);
                    AvisoEnviado := false;
                end;
            end;
        }
        field(50034; DiasAntesAviso; Integer)
        {
            Caption = 'Días antes para avisar';
            DataClassification = ToBeClassified;
            MinValue = 0;

            trigger OnValidate()
            begin
                ActualizarFechaAviso();
            end;
        }
        field(50035; FechaAviso; Date)
        {
            Caption = 'Día de aviso';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(50036; AvisoEnviado; Boolean)
        {
            Caption = 'Aviso enviado';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(50037; SiguienteOcurrenciaCreada; Boolean)
        {
            Caption = 'Siguiente ocurrencia creada';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(50038; Grupo; Code[20])
        {
            Caption = 'Grupo';
            DataClassification = CustomerContent;

        }
        modify("Percent Complete")
        {
            trigger OnAfterValidate()
            begin
                if "Percent Complete" = 100 then
                    Validate(Estado, Estado::Finalizado);
            end;
        }
        //Eliminar Tarea
        field(50039; EliminarTarea; Boolean)
        {
            Caption = 'Eliminar Tarea';
            DataClassification = ToBeClassified;
        }
        field(50040; "Tipo objetivo"; Option)
        {
            Caption = 'Tipo objetivo';
            DataClassification = CustomerContent;
            OptionMembers = " ",Limpieza,"Revisión","Limpieza techos","Limpieza a presión",Mantenimiento;
        }
        field(50041; "Veces objetivo"; Integer)
        {
            Caption = 'Veces objetivo';
            DataClassification = CustomerContent;
            MinValue = 0;
        }
        field(50042; "Periodo objetivo"; Option)
        {
            Caption = 'Periodo objetivo';
            DataClassification = CustomerContent;
            OptionMembers = " ",Semana,Mes;
        }
    }
    trigger OnAfterDelete()
    var
        Gtask: Codeunit GTask;
    begin
        Gtask.DeleteTarea(Rec.Id_Tarea);
    end;

    trigger OnAfterModify()
    begin
        if (Estado = Estado::Finalizado) and RecurrenciaActiva and (not SiguienteOcurrenciaCreada) then
            CrearSiguienteOcurrencia();
    end;

    procedure ActualizarFechaAviso()
    begin
        if not Avisar then begin
            Clear(FechaAviso);
            exit;
        end;
        if "Due DateTime" = 0DT then begin
            Clear(FechaAviso);
            exit;
        end;
        if DiasAntesAviso < 0 then
            DiasAntesAviso := 0;
        FechaAviso := CalcDate(StrSubstNo('<-%1D>', DiasAntesAviso), DT2Date("Due DateTime"));
        if FechaAviso <> xRec.FechaAviso then
            AvisoEnviado := false;
    end;

    local procedure ActualizarTextoRecurrencia()
    begin
        if not RecurrenciaActiva then begin
            Clear(TextoRecurrencia);
            exit;
        end;
        if Format(FormulaRecurrencia) <> '' then
            TextoRecurrencia := CopyStr(Format(FormulaRecurrencia), 1, MaxStrLen(TextoRecurrencia))
        else
            Clear(TextoRecurrencia);
        if RecurrenciaFin <> 0D then
            TextoRecurrencia := CopyStr(TextoRecurrencia + ' · hasta ' + Format(RecurrenciaFin), 1, MaxStrLen(TextoRecurrencia));
    end;

    procedure CopiarCamposPersonalizadosDesde(Origen: Record "User Task")
    begin
        Supervisor := Origen.Supervisor;
        Departamento := Origen.Departamento;
        Servicio := Origen.Servicio;
        Categoría := Origen.Categoría;
        "User Task Group Assigned To" := Origen."User Task Group Assigned To";
        Id_record := Origen.Id_record;
        "Object ID" := Origen."Object ID";
        "Object Type" := Origen."Object Type";
        OrdenFijacion := Origen.OrdenFijacion;
        "Job No." := Origen."Job No.";
        Reserva := Origen.Reserva;
        Resource := Origen.Resource;
        IdQr := Origen.IdQr;
        OrdenRetirada := Origen.OrdenRetirada;
        ZonaLimpieza := Origen.ZonaLimpieza;
        TipoTarea := Origen.TipoTarea;
        "Tipo objetivo" := Origen."Tipo objetivo";
        "Veces objetivo" := Origen."Veces objetivo";
        "Periodo objetivo" := Origen."Periodo objetivo";
        EsPeriodica := Origen.EsPeriodica;
        CrearParte := Origen.CrearParte;
        EmpresaTarea := Origen.EmpresaTarea;
        RecurrenciaActiva := Origen.RecurrenciaActiva;
        FormulaRecurrencia := Origen.FormulaRecurrencia;
        TextoRecurrencia := Origen.TextoRecurrencia;
        RecurrenciaFin := Origen.RecurrenciaFin;
        Avisar := Origen.Avisar;
        DiasAntesAviso := Origen.DiasAntesAviso;
        Priority := Origen.Priority;
    end;

    procedure CrearSiguienteOcurrencia(): Boolean
    var
        Nueva: Record "User Task";
        FechaBaseVenc: Date;
        FechaBaseInicio: Date;
        ProxVenc: Date;
        ProxInicio: Date;
        Gtask: Codeunit Gtask;
        Recurso: Record Resource;
        Emplaz: Record Emplazamientos;
        NoRecurso: Code[20];
        JobSetup: Record "Jobs Setup";
        Procesos_GTask: Codeunit Procesos_GTask;
    begin
        if not RecurrenciaActiva or SiguienteOcurrenciaCreada then
            exit(false);
        if Format(FormulaRecurrencia) = '' then
            exit(false);

        FechaBaseVenc := DT2Date("Due DateTime");
        if FechaBaseVenc = 0D then
            FechaBaseVenc := DT2Date("Start DateTime");
        if FechaBaseVenc = 0D then
            FechaBaseVenc := WorkDate();

        ProxVenc := CalcDate(FormulaRecurrencia, FechaBaseVenc);
        if (RecurrenciaFin <> 0D) and (ProxVenc > RecurrenciaFin) then begin
            SiguienteOcurrenciaCreada := true;
            Modify(true);
            exit(false);
        end;

        FechaBaseInicio := DT2Date("Start DateTime");
        if FechaBaseInicio = 0D then
            ProxInicio := ProxVenc
        else
            ProxInicio := CalcDate(FormulaRecurrencia, FechaBaseInicio);

        Nueva.Init();
        Nueva.Validate(Title, Title);
        Nueva.SetDescription(GetDescription());
        Nueva."Assigned To" := "Assigned To";
        Nueva."Created By" := "Created By";
        Nueva.Validate("Created DateTime", CurrentDateTime);
        Nueva.CopiarCamposPersonalizadosDesde(Rec);
        Nueva.Estado := Nueva.Estado::Pendiente;
        Nueva."Percent Complete" := 0;
        Clear(Nueva.Id_Tarea);
        Nueva.AvisoEnviado := false;
        Nueva.SiguienteOcurrenciaCreada := false;
        Nueva.DependenciaCreada := false;
        if TareaRecurrenteOrigen = 0 then
            Nueva.TareaRecurrenteOrigen := ID
        else
            Nueva.TareaRecurrenteOrigen := TareaRecurrenteOrigen;
        Nueva."Start DateTime" := CreateDateTime(ProxInicio, DT2Time("Start DateTime"));
        Nueva."Due DateTime" := CreateDateTime(ProxVenc, DT2Time("Due DateTime"));
        Nueva.ActualizarFechaAviso();
        Procesos_GTask.ActualizarGrupoTarea(Nueva, false);
        Nueva.Insert(true);
        Nueva."No." := Format(Nueva.ID);
        Nueva.Modify(true);

        SiguienteOcurrenciaCreada := true;
        Modify(true);

        JobSetup.Get();
        if JobSetup."Es Debug" then
            exit(true);

        NoRecurso := Resource;
        if (NoRecurso = '') and (Id_record.TableNo = Database::Emplazamientos) then
            if Emplaz.Get(Id_record) then
                NoRecurso := Emplaz."Nº Emplazamiento";
        if (NoRecurso = '') and (Id_record.TableNo = Database::Resource) then
            if Recurso.Get(Id_record) then
                NoRecurso := Recurso."No.";

        Gtask.CrearTareaTecnico(NoRecurso, Nueva, Nueva.Departamento, Nueva.Servicio, Nueva.CrearParte);
        exit(true);
    end;

    procedure GetMentioned(): Text
    var
        TempBlob: Codeunit "Temp Blob";
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        TempBlob.FromRecord(Rec, FieldNo(Mentioned));
        TempBlob.CreateInStream(InStream, TEXTENCODING::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

    procedure SetMentioned(StreamText: Text)
    var
        OutStream: OutStream;
    begin
        Clear(Mentioned);
        Description.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.Write(StreamText);
        if Modify(true) then;
    end;

    procedure CalcularProximoDiaLimpieza(ZonaLimpieza: Record "Zonas Limpieza"; Fecha: Date): Date
    var
        PeriodicidadZona: Record "Periodicidad Zona Limpieza";
        FechaBusqueda: Date;
        MaxIteraciones: Integer;
    begin
        // Si hay reglas de periodicidad definidas en la tabla, usarlas (solo días laborables L-V y sin festivos)
        PeriodicidadZona.SetRange("Id Zona Limpieza", ZonaLimpieza.Id);
        if PeriodicidadZona.FindFirst() then begin
            FechaBusqueda := Fecha;
            MaxIteraciones := 366;
            while MaxIteraciones > 0 do begin
                FechaBusqueda := FechaBusqueda + 1;
                if CoincideConPeriodicidadZona(FechaBusqueda, ZonaLimpieza.Id) then
                    exit(FechaBusqueda);
                MaxIteraciones -= 1;
            end;
            if not EsDiaLaborable(FechaBusqueda) then begin
                while not EsDiaLaborable(FechaBusqueda) do
                    FechaBusqueda := FechaBusqueda + 1;
            end;

            exit(0D); // No se encontró próxima fecha en el año
        end;
        // Respaldo: lógica antigua con Periodicidad/Periodicidad Invierno si existen en la zona
        // exit(CalcularProximoDiaLimpiezaLegacy(ZonaLimpieza, Fecha));
    end;

    // local procedure CalcularProximoDiaLimpiezaLegacy(ZonaLimpieza: Record "Zonas Limpieza"; Fecha: Date): Date
    // var
    //     FechaActual: Date;
    //     IsWinter: Boolean;
    //     Periodicidad: DateFormula;
    // begin
    //     if Date2DMY(Fecha, 2) in [1, 2, 3, 10, 11, 12] then
    //         IsWinter := true;
    //     if IsWinter then
    //         FechaActual := CalcDate(ZonaLimpieza."Periodicidad Invierno", Fecha)
    //     else
    //         FechaActual := CalcDate(ZonaLimpieza."Periodicidad", Fecha);
    //     exit(FechaActual);
    // end;

    // procedure CalcularPeriodicidad(ZonaLimpieza: Record "Zonas Limpieza"; Fecha: Date): DateFormula
    // var
    //     IsWinter: Boolean;
    //     Periodicidad: DateFormula;
    // begin
    //     if Date2DMY(Fecha, 2) in [1, 2, 3, 10, 11, 12] then
    //         IsWinter := true;
    //     if IsWinter then
    //         Periodicidad := ZonaLimpieza."Periodicidad Invierno"
    //     else
    //         Periodicidad := ZonaLimpieza."Periodicidad";
    //     exit(Periodicidad);
    // end;

    local procedure EsDiaLaborable(Fecha: Date): Boolean
    var
        Calendario: Record "Base Calendar Change";
    begin
        Calendario.ChangeCompany('Malla Publicidad');
        Calendario.SetRange("Date", Fecha);
        If Calendario.FindFirst() then begin
            If Calendario.Nonworking Then exit(false);
            If (Calendario.Day = Calendario.Day::Sunday) or (Calendario.Day = Calendario.Day::Saturday) Then exit(false);
        end;
        exit(true);
    end;

    local procedure CoincideConPeriodicidadZona(Fecha: Date; IdZonaLimpieza: Integer): Boolean
    var
        PeriodicidadZona: Record "Periodicidad Zona Limpieza";
        DiaSemana: Integer;
        DiaDelMes: Integer;
        Mes: Integer;
        DíaSemanaEnum: Enum "Día Semana Limpieza";
    begin
        PeriodicidadZona.SetRange("Id Zona Limpieza", IdZonaLimpieza);
        if not PeriodicidadZona.FindSet() then
            exit(false);
        DiaSemana := Date2DWY(Fecha, 1);
        DiaDelMes := Date2DMY(Fecha, 1);
        Mes := Date2DMY(Fecha, 2); // meses invierno: 11, 12, 1, 2, 3
        repeat
            if not AplicaLineaEnFecha(PeriodicidadZona.Temporada, Mes) then
                continue;
            case PeriodicidadZona."Tipo Periodicidad" of
                PeriodicidadZona."Tipo Periodicidad"::"Día semanal":
                    if (PeriodicidadZona."Día Semana" <> DíaSemanaEnum::Ninguno) and
                       CoincideDiaSemana(DiaSemana, PeriodicidadZona."Día Semana")
                    then
                        exit(true);
                PeriodicidadZona."Tipo Periodicidad"::"Día del mes":
                    if (PeriodicidadZona."Día del mes" >= 1) and (PeriodicidadZona."Día del mes" <= 31) and
                       (DiaDelMes = PeriodicidadZona."Día del mes")
                    then
                        exit(true);
            end;
        until PeriodicidadZona.Next() = 0;
        exit(false);
    end;

    local procedure AplicaLineaEnFecha(Temporada: Enum "Temporada Limpieza"; Mes: Integer): Boolean
    begin
        case Temporada of
            Temporada::Todas:
                exit(true);
            Temporada::Invierno:
                exit(Mes in [1, 2, 11, 12]); // nov, dic, ene, feb
            Temporada::Verano:
                exit(Mes in [3, 4, 5, 6, 7, 8, 9, 10]); // mar, abr, may, jun, jul, ago, sep, oct
            else
                exit(true);
        end;
    end;

    local procedure CoincideDiaSemana(DiaSemanaNum: Integer; DíaSemana: Enum "Día Semana Limpieza"): Boolean
    begin
        case DíaSemana of
            DíaSemana::Lunes:
                exit(DiaSemanaNum = 1);
            DíaSemana::Martes:
                exit(DiaSemanaNum = 2);
            DíaSemana::Miércoles:
                exit(DiaSemanaNum = 3);
            DíaSemana::Jueves:
                exit(DiaSemanaNum = 4);
            DíaSemana::Viernes:
                exit(DiaSemanaNum = 5);
            else
                exit(false);
        end;
    end;

    procedure CrearDependencia(): Boolean
    var
        FechaActual: Date;
        DiaSemana: Integer;
        DiasAñadir: Integer;
        MaxDias: Integer;
        IsWinter: Boolean;
        Periodicidad: DateFormula;
        Gtask: Codeunit Gtask;
        RecorId: RecordId;
        RecRef: RecordRef;
        Descripcion: Text;
        ZonaLimpieza: Record "Zonas Limpieza";
        FechaInicio: Date;
    begin
        // Salir si la tarea no está asociada a una zona de limpieza (evita error en Get y crea dependencia solo para tareas de limpieza)
        if Rec.ZonaLimpieza = 0 then
            exit(false);
        if not ZonaLimpieza.Get(Rec.ZonaLimpieza) then
            exit(false);
        // Salir si no hay registro vinculado (evita error en RecRef.Get)
        RecorId := Rec.Id_record;
        if not RecRef.Get(RecorId) then
            exit(false);

        Descripcion := Rec.GetDescription();
        FechaInicio := Rec.CalcularProximoDiaLimpieza(ZonaLimpieza, WorkDate());
        //Si la proxima fechainicio es igual que la fecha de la tAREA ACTUAL, crear LA DEPENDENCIA, CON WORKDATE + 1 DIA
        iF FechaInicio = DT2Date(Rec."Start DateTime") then
            FechaInicio := Rec.CalcularProximoDiaLimpieza(ZonaLimpieza, Calcdate('+1D', WorkDate()));
        If Gtask.CrearTareaLimpieza(Rec.TipoTarea, RecRef, Rec.Title, Rec.ZonaLimpieza, Descripcion
                                     , false, '', FechaInicio, true, Rec.Id) then begin
            Rec.Get(Rec.Id);
            Rec.DependenciaCreada := true;
            Rec.Estado := Rec.Estado::Finalizado;
            Rec.Modify(true);
            exit(true);
        end;
        exit(false);
    end;
}
tableextension 90109 Tareascomercial extends "To-do"
{
    fields
    {
        field(50000; Id_Tarea; Text[250])
        {
            Caption = 'Id_tarea';
            DataClassification = ToBeClassified;
        }
        field(50001; Responsable; guid)
        {
            Caption = 'Responsable';
            DataClassification = ToBeClassified;
            TableRelation = User."User Security ID";//WHERE("License Type" = CONST("Full User"));


        }
        field(50002; Categoria; Code[20])
        {
            Caption = 'Categoría';
            DataClassification = ToBeClassified;
            TableRelation = "User Task Group"."Code";
        }
        field(50003; Departamento; Code[20])
        {
            Caption = 'Departamento';
            DataClassification = ToBeClassified;
            TableRelation = "Responsibility Center"."Code";
        }



    }
    trigger OnAfterModify()
    var
        Gtastk: Codeunit GTask;
    begin
        if ("Start Time" <> 0T) and (Id_Tarea = '') then
            Gtastk.CrearTareaTodo(Rec);
    end;

}