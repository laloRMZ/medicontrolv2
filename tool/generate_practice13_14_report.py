from pathlib import Path
from pypdf import PdfReader, PdfWriter
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import (
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

ROOT = Path(__file__).resolve().parent.parent
PORTADA_PATH = Path(r"C:\Users\edurm\Downloads\Portada.pdf")
BODY_PDF = ROOT / "build" / "practica13_14_body.pdf"
FINAL_PDF = ROOT / "PRACTICA_13_14_AUTOMATIZACION_CI_ENTREGA.pdf"


def build_body_pdf(output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    doc = SimpleDocTemplate(
        str(output_path),
        pagesize=A4,
        leftMargin=14 * mm,
        rightMargin=14 * mm,
        topMargin=13 * mm,
        bottomMargin=13 * mm,
    )

    styles = getSampleStyleSheet()
    navy = colors.HexColor("#10375C")
    slate = colors.HexColor("#334155")
    light_bg = colors.HexColor("#F1F5F9")
    border = colors.HexColor("#CBD5E1")
    green_bg = colors.HexColor("#DCFCE7")
    green_fg = colors.HexColor("#166534")

    h1 = ParagraphStyle(
        "H1",
        parent=styles["Heading1"],
        fontName="Helvetica-Bold",
        fontSize=13,
        leading=16,
        textColor=navy,
        spaceAfter=4,
    )
    h2 = ParagraphStyle(
        "H2",
        parent=styles["Heading2"],
        fontName="Helvetica-Bold",
        fontSize=9.8,
        leading=12,
        textColor=navy,
        spaceBefore=6,
        spaceAfter=3,
    )
    body = ParagraphStyle(
        "Body",
        parent=styles["Normal"],
        fontName="Helvetica",
        fontSize=8.0,
        leading=10.5,
        textColor=slate,
        spaceAfter=3,
    )
    cell = ParagraphStyle(
        "Cell",
        parent=styles["Normal"],
        fontName="Helvetica",
        fontSize=7.1,
        leading=9.0,
        textColor=slate,
    )
    cell_bold = ParagraphStyle(
        "CellBold",
        parent=cell,
        fontName="Helvetica-Bold",
        textColor=navy,
    )
    cell_ok = ParagraphStyle(
        "CellOk",
        parent=cell,
        fontName="Helvetica-Bold",
        textColor=green_fg,
    )

    def make_table(rows, col_widths):
        t = Table(rows, colWidths=col_widths, repeatRows=1)
        t.setStyle(
            TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, 0), navy),
                    ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                    ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                    ("FONTSIZE", (0, 0), (-1, 0), 7.3),
                    ("VALIGN", (0, 0), (-1, -1), "TOP"),
                    ("GRID", (0, 0), (-1, -1), 0.4, border),
                    ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, light_bg]),
                    ("LEFTPADDING", (0, 0), (-1, -1), 4),
                    ("RIGHTPADDING", (0, 0), (-1, -1), 4),
                    ("TOPPADDING", (0, 0), (-1, -1), 3),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
                ]
            )
        )
        return t

    story = []
    story.append(
        Paragraph(
            "Prácticas 13 y 14: Automatización de Pruebas y Validación Continua — MediControl V2",
            h1,
        )
    )
    story.append(
        Paragraph(
            "<b>Repositorio:</b> laloRMZ/medicontrolv2 (main, commit 25a772e) | "
            "<b>Fecha:</b> 17 nov 2026 | "
            "<b>Entorno:</b> Flutter 3.47.9 / Dart 3.13.7, Node.js 22, GitHub Actions (ubuntu-latest)",
            body,
        )
    )

    # Fase 1
    story.append(Paragraph("Fase 1. Selección de componentes críticos y riesgos prevenibles", h2))
    f1_rows = [
        ["Categoría", "Componente / Archivo", "Defecto o riesgo prevenible"],
        [
            Paragraph("Función crítica móvil", cell_bold),
            Paragraph("AppointmentLogic<br/>(lib/services/appointment_logic.dart)", cell),
            Paragraph(
                "Validación incorrecta de fechas pasadas o campos vacíos, desorden cronológico y discrepancia de tipos en IDs (int vs String).",
                cell,
            ),
        ],
        [
            Paragraph("Servicio / Comunicación", cell_bold),
            Paragraph("ApiService y AuthService<br/>(lib/services/api_service.dart)", cell),
            Paragraph(
                "Propagación no controlada de errores HTTP (500/503), timeouts u omisión del header Authorization: Bearer.",
                cell,
            ),
        ],
        [
            Paragraph("Persistencia", cell_bold),
            Paragraph("SharedPreferences y SQLite<br/>(auth_service.dart / backend/server.js)", cell),
            Paragraph(
                "Caída por JSON corrupto en user_data, persistencia residual tras logout y falta de exportación {app, db} en server.js.",
                cell,
            ),
        ],
    ]
    story.append(make_table(f1_rows, [36 * mm, 58 * mm, 88 * mm]))

    # Fase 2 y Fase 3
    story.append(Paragraph("Fases 2 y 3. Pruebas unitarias (6 nuevas + 4 previas) e integración (4 Flutter + 3 Backend)", h2))
    story.append(
        Paragraph(
            "<b>Pruebas unitarias (test/unit/practica13_unit_test.dart):</b> "
            "(1) <i>Entrada válida:</i> trim de campos y formatDate ('5 dic 2026'); "
            "(2) <i>Entrada vacía/nula:</i> rechazo de campos vacíos, findNextAppointment([]) y getStoredUser() null; "
            "(3) <i>Fuera de rango:</i> fecha pasada (-2 min) y JWT malformado en isTokenExpired(); "
            "(4) <i>Resultado esperado:</i> sortChronologically sin mutar lista original y selección de próxima cita; "
            "(5) <i>Excepción JSON:</i> tolerancia a JSON corrupto en SharedPreferences; "
            "(6) <i>Excepción HTTP:</i> excepción descriptiva ante HTTP 500 en ApiService.",
            body,
        )
    )
    story.append(
        Paragraph(
            "<b>Pruebas de integración (test/integration/api_persistence_integration_test.dart + backend/test/appointments_integration.test.js):</b> "
            "Uso de HttpServer real en 127.0.0.1:0 y SharedPreferences en memoria para validar envío de Bearer token y deserialización HTTP 200 "
            "de citas y perfil (AUT-04), propagación controlada ante HTTP 503 (AUT-05), ciclo guardar/leer/limpiar sesión en SharedPreferences (AUT-06) "
            "y persistencia física POST/GET/DELETE en SQLite.",
            body,
        )
    )

    # Fase 4 y Fase 5
    story.append(Paragraph("Fases 4 y 5. Pipeline CI (.github/workflows/ci.yml), validación y correcciones", h2))
    f5_rows = [
        ["Ejecución", "Pruebas", "Aprob.", "Fall.", "Tiempo", "Resultado / Evidencia"],
        [
            Paragraph("Local Flutter (unit + integration)", cell),
            Paragraph("14", cell),
            Paragraph("14", cell),
            Paragraph("0", cell),
            Paragraph("11.16 s", cell),
            Paragraph("Aprobado (flutter analyze sin incidencias)", cell_ok),
        ],
        [
            Paragraph("Local Backend (npm test)", cell),
            Paragraph("3", cell),
            Paragraph("3", cell),
            Paragraph("0", cell),
            Paragraph("1.25 s", cell),
            Paragraph("Aprobado (API REST + SQLite)", cell_ok),
        ],
        [
            Paragraph("CI Run #1 (809d003)", cell),
            Paragraph("16", cell),
            Paragraph("12", cell),
            Paragraph("2", cell),
            Paragraph("~59 s", cell),
            Paragraph("Falló: server.js sin export {app,db} y ID int(1) vs '1'", cell),
        ],
        [
            Paragraph("CI Run #2 (ac1b899, fix backend)", cell),
            Paragraph("17", cell),
            Paragraph("16", cell),
            Paragraph("1", cell),
            Paragraph("~71 s", cell),
            Paragraph("Backend 3/3 OK; persistía fallo en appointment_logic_test", cell),
        ],
        [
            Paragraph("CI Run #3 (25a772e, fix test)", cell),
            Paragraph("17", cell),
            Paragraph("17", cell),
            Paragraph("0", cell),
            Paragraph("~75 s", cell),
            Paragraph("Exitoso (Run ID 44223354257: Flutter 14/14 + Backend 3/3)", cell_ok),
        ],
    ]
    story.append(make_table(f5_rows, [45 * mm, 15 * mm, 14 * mm, 12 * mm, 16 * mm, 80 * mm]))
    story.append(Spacer(1, 3))
    story.append(
        Paragraph(
            "<b>Errores detectados y corregidos:</b> (a) Eliminación de 4 archivos vacíos (0 bytes) que rompían el compilador de pruebas; "
            "(b) Exportación de {app, db} en backend/server.js (commit ac1b899); "
            "(c) Corrección de tipo String ('1','2') en appointment_logic_test.dart (commit 25a772e). "
            "Nota: widget_test.dart y e2e_appointment_flow_test.dart requieren inicialización nativa de FirebaseAuth ([core/no-app]), "
            "por lo que CI ejecuta explícitamente las suites desacopladas test/unit y test/integration.",
            body,
        )
    )

    # Matriz de Automatización
    story.append(Paragraph("Matriz de Automatización", h2))
    m_rows = [
        ["ID", "Tipo", "Descripción / Caso automatizado", "Evidencia", "Estado"],
        [
            Paragraph("AUT-01", cell_bold),
            Paragraph("Unitarias", cell),
            Paragraph("Entrada válida (trim, formatDate) y entrada vacía/nula en citas y AuthService.", cell),
            Paragraph("practica13_unit_test.dart (1-2)", cell),
            Paragraph("Aprobado", cell_ok),
        ],
        [
            Paragraph("AUT-02", cell_bold),
            Paragraph("Unitarias", cell),
            Paragraph("Valores fuera de rango (fecha pasada >1 min, JWT inválido) y ordenamiento/próxima cita.", cell),
            Paragraph("practica13_unit_test.dart (3-4)", cell),
            Paragraph("Aprobado", cell_ok),
        ],
        [
            Paragraph("AUT-03", cell_bold),
            Paragraph("Unitarias", cell),
            Paragraph("Manejo de excepciones: JSON corrupto en sesión local y HTTP 500 en ApiService.", cell),
            Paragraph("practica13_unit_test.dart (5-6)", cell),
            Paragraph("Aprobado", cell_ok),
        ],
        [
            Paragraph("AUT-04", cell_bold),
            Paragraph("Integración", cell),
            Paragraph("Comunicación ApiService -> AuthService -> HttpServer (200 OK, Bearer) y POST /api/appointments (201).", cell),
            Paragraph("api_persistence_integration_test.dart", cell),
            Paragraph("Aprobado", cell_ok),
        ],
        [
            Paragraph("AUT-05", cell_bold),
            Paragraph("Integración", cell),
            Paragraph("Respuesta controlada ante servidor no disponible (HTTP 503) y errores 400/404 REST.", cell),
            Paragraph("api_persistence_integration_test.dart", cell),
            Paragraph("Aprobado", cell_ok),
        ],
        [
            Paragraph("AUT-06", cell_bold),
            Paragraph("Persistencia", cell),
            Paragraph("Persistencia y limpieza en SharedPreferences y verificación física en SQLite.", cell),
            Paragraph("integration_test + appointments_integration.test.js", cell),
            Paragraph("Aprobado", cell_ok),
        ],
        [
            Paragraph("AUT-07", cell_bold),
            Paragraph("CI", cell),
            Paragraph("Pipeline en GitHub Actions ejecutando flutter analyze, flutter test y npm test en push/PR.", cell),
            Paragraph(".github/workflows/ci.yml", cell),
            Paragraph("Aprobado", cell_ok),
        ],
        [
            Paragraph("AUT-08", cell_bold),
            Paragraph("CI", cell),
            Paragraph("Re-ejecución continua tras corregir fallos de Run #1 hasta lograr 17/17 en Run #3.", cell),
            Paragraph("Actions Run 44223354257", cell),
            Paragraph("Aprobado", cell_ok),
        ],
    ]
    t_matrix = make_table(m_rows, [16 * mm, 22 * mm, 79 * mm, 45 * mm, 20 * mm])
    t_matrix.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (4, 1), (4, -1), green_bg),
                ("ALIGN", (4, 1), (4, -1), "CENTER"),
            ]
        )
    )
    story.append(t_matrix)

    # Fase 6
    story.append(Paragraph("Fase 6. Conclusiones", h2))
    story.append(
        Paragraph(
            "La automatización de pruebas unitarias, de integración y su ejecución continua en GitHub Actions garantiza que cada cambio "
            "integrado en MediControl V2 sea verificado de manera objetiva y reproducible. En esta práctica, el flujo CI detectó de inmediato "
            "dos regresiones reales (una discrepancia de tipos en appointment_logic_test.dart y la falta de exportación de {app, db} en "
            "backend/server.js) antes de consolidar cambios posteriores. Al ejecutar automáticamente el análisis estático y las 17 pruebas "
            "en ~75 segundos ante cada push o pull request, se protege la estabilidad de la lógica de negocio, los contratos de red y la "
            "persistencia tras futuras modificaciones.",
            body,
        )
    )

    doc.build(story)


def merge_with_portada(portada_path: Path, body_path: Path, final_path: Path) -> None:
    writer = PdfWriter()
    portada_reader = PdfReader(str(portada_path))
    body_reader = PdfReader(str(body_path))

    for page in portada_reader.pages:
        writer.add_page(page)
    for page in body_reader.pages:
        writer.add_page(page)

    with open(final_path, "wb") as f:
        writer.write(f)

    print(
        f"Generated {final_path} ({len(portada_reader.pages)} portada + {len(body_reader.pages)} body = {len(writer.pages)} pages)"
    )


if __name__ == "__main__":
    build_body_pdf(BODY_PDF)
    merge_with_portada(PORTADA_PATH, BODY_PDF, FINAL_PDF)
