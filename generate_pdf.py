#!/usr/bin/env python3
import os
import sys
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, KeepTogether
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors
from reportlab.pdfgen import canvas

# Define custom page numbering canvas for "Page X of Y" and header/footer borders
class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super().showPage()
        super().save()

    def draw_page_decorations(self, page_count):
        self.saveState()
        
        # We only draw headers and footers on pages (if multi-page, or all pages)
        self.setFont("Helvetica-Bold", 8)
        self.setFillColor(colors.HexColor("#6B1724")) # Burgundy
        
        # Header
        self.drawString(54, 755, "HORDE OF HORRORS — DEVELOPMENT ROADMAP")
        
        # Header Line (Burgundy + Gold accent lines)
        self.setStrokeColor(colors.HexColor("#6B1724"))
        self.setLineWidth(1)
        self.line(54, 747, 558, 747)
        
        self.setStrokeColor(colors.HexColor("#C5A059")) # Old Gold
        self.setLineWidth(0.5)
        self.line(54, 745, 558, 745)
        
        # Footer
        self.setFont("Helvetica", 8)
        self.setFillColor(colors.HexColor("#555555"))
        self.drawString(54, 45, "Confidential — Internal Presentational Copy")
        
        page_text = f"Page {self._pageNumber} of {page_count}"
        self.drawRightString(558, 45, page_text)
        
        # Footer Lines
        self.setStrokeColor(colors.HexColor("#C5A059"))
        self.setLineWidth(0.5)
        self.line(54, 55, 558, 55)
        
        self.restoreState()


def build_pdf(filename="development_status.pdf"):
    # Margins: 0.75 in top/bottom, 0.75 in left/right (54 points)
    # Available width: 612 - 108 = 504 pt.
    doc = SimpleDocTemplate(
        filename,
        pagesize=letter,
        leftMargin=54,
        rightMargin=54,
        topMargin=72,
        bottomMargin=72
    )

    styles = getSampleStyleSheet()
    
    # Custom colors
    burgundy = colors.HexColor("#6B1724")
    charcoal = colors.HexColor("#2C2C2C")
    gold = colors.HexColor("#C5A059")
    cream_bg = colors.HexColor("#FCFBF9")
    
    # Modify/Add styles
    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Normal'],
        fontName='Times-Bold',
        fontSize=24,
        leading=28,
        textColor=burgundy,
        alignment=1, # Center
        spaceAfter=4
    )
    
    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Times-Italic',
        fontSize=12,
        leading=14,
        textColor=colors.HexColor("#555555"),
        alignment=1, # Center
        spaceAfter=15
    )
    
    section_style = ParagraphStyle(
        'SectionHeader',
        parent=styles['Normal'],
        fontName='Times-Bold',
        fontSize=14,
        leading=16,
        textColor=burgundy,
        spaceBefore=12,
        spaceAfter=6
    )
    
    card_title_style = ParagraphStyle(
        'CardTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=11,
        leading=13,
        textColor=colors.HexColor("#222222")
    )
    
    card_text_style = ParagraphStyle(
        'CardText',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9.5,
        leading=12,
        textColor=colors.HexColor("#444444")
    )

    # Table cell paragraph styles
    cell_hdr_style = ParagraphStyle(
        'CellHeader',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=9,
        leading=11,
        textColor=colors.white,
        alignment=0
    )
    
    cell_body_style = ParagraphStyle(
        'CellBody',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8.5,
        leading=10.5,
        textColor=charcoal
    )
    
    cell_body_bold = ParagraphStyle(
        'CellBodyBold',
        parent=cell_body_style,
        fontName='Helvetica-Bold'
    )
    
    # Badges for status
    badge_completed = ParagraphStyle(
        'BadgeCompleted',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=8,
        leading=10,
        textColor=colors.HexColor("#0F5132"), # Dark Green
        alignment=1 # Center
    )
    
    badge_pending = ParagraphStyle(
        'BadgePending',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=8,
        leading=10,
        textColor=colors.HexColor("#664D03"), # Dark Yellow/Brown
        alignment=1 # Center
    )

    story = []

    # Title
    story.append(Spacer(1, 10))
    story.append(Paragraph("HORDE OF HORRORS", title_style))
    story.append(Paragraph("Comprehensive Status & Executive Development Roadmap", subtitle_style))
    story.append(Spacer(1, 10))

    # Summary Box (Progress Overview)
    total_tasks = 28
    completed_tasks = 11
    percent = int((completed_tasks / total_tasks) * 100)
    
    summary_data = [
        [
            Paragraph("<b>PROJECT COMPLETION METRIC</b>", card_title_style),
            Paragraph(f"<b>STATUS:</b> {completed_tasks} / {total_tasks} Tasks Finalized ({percent}%)", card_title_style)
        ],
        [
            Paragraph("Horde of Horrors is a portrait-oriented, mobile-first gothic horror wave survival game written in Godot 4.3 GDScript. Development is proceeding along two parallel streams: full-featured game client architecture and an automated Grok chat bridging loop.", card_text_style),
            Paragraph("<b>Core Pillars:</b><br/>• Mobile Portrait optimization (touch controls, virtual joystick)<br/>• Fast-paced horde pathfinding AI state loops<br/>• Comprehensive custom pooling framework (`PoolManager.gd`)", card_text_style)
        ]
    ]
    
    summary_table = Table(summary_data, colWidths=[252, 252])
    summary_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#F8F9FA")),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor("#E2E8F0")),
        ('TOPPADDING', (0,0), (-1,-1), 10),
        ('BOTTOMPADDING', (0,0), (-1,-1), 10),
        ('LEFTPADDING', (0,0), (-1,-1), 12),
        ('RIGHTPADDING', (0,0), (-1,-1), 12),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('SPAN', (0,0), (0,0)), # No spans, columns side-by-side
    ]))
    
    story.append(summary_table)
    story.append(Spacer(1, 15))

    # Table Column Widths (Must sum to 504 pt)
    col_widths = [85, 175, 64, 180]
    
    # Table Headers
    table_content = [[
        Paragraph("Phase / Category", cell_hdr_style),
        Paragraph("Task Description", cell_hdr_style),
        Paragraph("Status", cell_hdr_style),
        Paragraph("Target / Notes", cell_hdr_style)
    ]]

    # Table Row Data
    tasks_data = [
        ("Active Fixes", "Refactor Enemy.gd bat transform scaling transitions", "Completed", "Scales bat to 0.15 and restores humanoid to 0.55"),
        ("Active Fixes", "Implement HUD container in UIManager.tscn to toggle visibility", "Completed", "Hides HUD on main/select menus, shows automatically on wave start"),
        ("Active Fixes", "Fix AudioManager.gd startup child node lookups", "Completed", "Dynamically instantiates players instead of hardcoded paths"),
        ("Active Fixes", "Resolve UpgradeShop node name mismatch in UIManager", "Completed", "Renamed UpgradePanel instance to UpgradeShop"),
        ("Foundation", "Register new singletons/autoloads in project.godot", "Completed", "Added UIManager, PoolManager, GameManager, WaveManager"),
        ("Foundation", "Debug and clean up EnemyBase.gd duplicate code", "Completed", "Restored clean variables and methods"),
        ("Foundation", "Fix invalid .tscn syntax for all 6 enemy scenes", "Completed", "Rebuilt scenes using valid Godot 4.3 blocks"),
        ("Foundation", "Verify input mapping for dash action", "Completed", "Shift key bound physically in project settings"),
        ("Foundation", "Connect UpgradeShop.tscn to UIManager.gd", "Completed", "Integrated upgrade menu logic and overlay triggers"),
        ("Foundation", "Integrate object pooling inside EnemyBase.gd", "Completed", "Unified return-to-pool calls and reset behaviors"),
        ("Foundation", "Set up the first dynamic level layout folder structure", "Completed", "Implemented dynamic backdrop swapping in MainGame"),
        ("Week 1", "Implement virtual joystick CanvasLayer (Joystick.tscn)", "Pending", "Mobile portrait layout touch movement"),
        ("Week 1", "Implement auto-aim target scanning using Area2D", "Pending", "Automatic targeting of nearest active monster"),
        ("Week 1", "Add player character animated sprite states", "Pending", "Walk, idle, fire, dash frame transitions"),
        ("Week 2", "Set up silver crossbow weapon custom Resource parameters", "Pending", "Damage, speed, fire-rate balancing templates"),
        ("Week 2", "Integrate projectile pooling using PoolManager", "Pending", "Reuses bolts and hit impact particles"),
        ("Week 2", "Improve basic pathfinding/chase logic on EnemyBase.gd", "Pending", "Navigation agent setup for smarter pathing"),
        ("Week 3", "Implement detailed Upgrade UI cards in shop", "Pending", "Offense, Defense, Utility, and custom Sinister cards"),
        ("Week 3", "Create pickup items dropping on enemy deaths", "Pending", "Blood drops, speed boosts, invincibility bubbles"),
        ("Week 4", "Add characters Elias Voss & Serena Nightshade", "Pending", "Roster properties and selection transitions"),
        ("Week 4", "Implement Werewolf dash & Vampire bat AI state machines", "Pending", "Advanced monster combat actions"),
        ("Week 4", "Build maps for Cathedral, Mansion, and Ruins", "Pending", "Dynamic Y-sorted environment layers"),
        ("Week 5", "Add screenshake shader to camera", "Pending", "Juice impact reactions on hit"),
        ("Week 5", "Add GPU-based blood particles on death", "Pending", "Dynamic death splatters"),
        ("Week 5", "Implement visibility-based processing optimization", "Pending", "Pauses AI loops when off-screen"),
        ("Week 6", "Set up JSON serialization for game saves", "Pending", "Persistent stats, high-scores, essence"),
        ("Week 6", "Add Victor Van Helsing premium character configuration", "Pending", "Premium roster expansion"),
        ("Week 6", "Configure Android and iOS export settings", "Pending", "Builds ready for staging/testing")
    ]

    t_style = [
        ('BACKGROUND', (0,0), (-1,0), burgundy),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#CBD5E1")),
        ('TOPPADDING', (0,0), (-1,-1), 5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 5),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]

    for idx, (phase, desc, status, notes) in enumerate(tasks_data):
        row_idx = idx + 1 # offset for header
        
        # Color phase based on type
        if "Fix" in phase:
            phase_p = Paragraph(f"<b>{phase}</b>", cell_body_bold)
        elif "Foundation" in phase:
            phase_p = Paragraph(f"<b>{phase}</b>", cell_body_bold)
        else:
            phase_p = Paragraph(phase, cell_body_style)
            
        desc_p = Paragraph(desc, cell_body_style)
        notes_p = Paragraph(notes, cell_body_style)
        
        if status == "Completed":
            status_p = Paragraph("COMPLETED", badge_completed)
            t_style.append(('BACKGROUND', (2, row_idx), (2, row_idx), colors.HexColor("#D1E7DD"))) # green cell bg
        else:
            status_p = Paragraph("PENDING", badge_pending)
            t_style.append(('BACKGROUND', (2, row_idx), (2, row_idx), colors.HexColor("#FFF3CD"))) # yellow cell bg

        # Alternating background colors for rows
        if row_idx % 2 == 0:
            t_style.append(('BACKGROUND', (0, row_idx), (1, row_idx), colors.HexColor("#F8F9FA")))
            t_style.append(('BACKGROUND', (3, row_idx), (3, row_idx), colors.HexColor("#F8F9FA")))
        else:
            t_style.append(('BACKGROUND', (0, row_idx), (1, row_idx), colors.white))
            t_style.append(('BACKGROUND', (3, row_idx), (3, row_idx), colors.white))

        table_content.append([phase_p, desc_p, status_p, notes_p])

    status_table = Table(table_content, colWidths=col_widths, repeatRows=1)
    status_table.setStyle(TableStyle(t_style))
    story.append(status_table)

    # Build the document
    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"PDF successfully built: {filename}")


if __name__ == "__main__":
    build_pdf()
