#!/usr/bin/env python3
import os
import sys
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, KeepTogether, Image
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors
from reportlab.pdfgen import canvas

LOGO_PATH = "/home/neo/.gemini/antigravity/scratch/horde-of-horrors/horde-of-horrors-godot/icon.png"

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
        
        # We only draw headers on page 2 and later (Page 1 has the letterhead/logo already)
        if self._pageNumber > 1:
            self.setFont("Helvetica-Bold", 8)
            self.setFillColor(colors.HexColor("#6B1724")) # Burgundy
            self.drawString(54, 755, "HORDE OF HORRORS — DEVELOPMENT BREAKDOWN")
            
            # Header lines
            self.setStrokeColor(colors.HexColor("#6B1724"))
            self.setLineWidth(1)
            self.line(54, 747, 558, 747)
            
            self.setStrokeColor(colors.HexColor("#C5A059")) # Old Gold
            self.setLineWidth(0.5)
            self.line(54, 745, 558, 745)
        
        # Footer (all pages)
        self.setFont("Helvetica", 8)
        self.setFillColor(colors.HexColor("#555555"))
        self.drawString(54, 45, "Confidential — Horde of Horrors Development Lab")
        
        page_text = f"Page {self._pageNumber} of {page_count}"
        self.drawRightString(558, 45, page_text)
        
        # Footer Lines
        self.setStrokeColor(colors.HexColor("#C5A059"))
        self.setLineWidth(0.5)
        self.line(54, 55, 558, 55)
        
        self.restoreState()


def build_breakdown_pdf(filename="development_breakdown.pdf"):
    # Margins: 54 pt (0.75 inch)
    # Page width: 612 pt. Available width: 504 pt.
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
    gold = colors.HexColor("#C5A059")
    charcoal = colors.HexColor("#2C2C2C")
    light_grey = colors.HexColor("#F8F9FA")
    border_grey = colors.HexColor("#E2E8F0")

    # Typography Styles
    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Normal'],
        fontName='Times-Bold',
        fontSize=26,
        leading=30,
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
    
    h1_style = ParagraphStyle(
        'H1',
        parent=styles['Normal'],
        fontName='Times-Bold',
        fontSize=14,
        leading=17,
        textColor=burgundy,
        spaceBefore=14,
        spaceAfter=8,
        keepWithNext=True
    )

    h2_style = ParagraphStyle(
        'H2',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=11,
        leading=13,
        textColor=burgundy,
        spaceBefore=8,
        spaceAfter=4,
        keepWithNext=True
    )
    
    body_style = ParagraphStyle(
        'Body',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9.5,
        leading=13.5,
        textColor=charcoal,
        spaceAfter=6
    )

    bullet_style = ParagraphStyle(
        'Bullet',
        parent=body_style,
        leftIndent=15,
        firstLineIndent=-10,
        spaceAfter=4
    )

    cell_hdr_style = ParagraphStyle(
        'CellHeader',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=9,
        leading=11,
        textColor=colors.white,
        alignment=0
    )

    story = []

    # 1. Letterhead Logo (centered)
    if os.path.exists(LOGO_PATH):
        # We scale the logo to be 64x64 pt
        logo_img = Image(LOGO_PATH, width=64, height=64)
        logo_img.hAlign = 'CENTER'
        story.append(logo_img)
        story.append(Spacer(1, 8))
    
    # Title
    story.append(Paragraph("HORDE OF HORRORS", title_style))
    story.append(Paragraph("Comprehensive Project Breakdown & Strategic Roadmap", subtitle_style))
    
    # Ornate gold line under the header
    story.append(Spacer(1, 4))
    
    # Section 1: Executive Summary
    story.append(Paragraph("1. Executive Project Summary", h1_style))
    story.append(Paragraph(
        "Horde of Horrors is a portrait-oriented, mobile-first gothic horror wave survival game written in Godot 4.3 GDScript. "
        "The project is architected around highly optimized components targetting 60 FPS performance on standard mobile devices. "
        "Our development pipeline operates in two parallel tracks: <b>core client game engineering</b> and an <b>automated Grok-AI communication bridge</b> "
        "that allows us to query live conversation logs, receive optimized codebase proposals, and maintain detailed documentation.",
        body_style
    ))

    # Section 2: What We Have Done
    story.append(Paragraph("2. Achievements & Completed Infrastructure", h1_style))
    
    completed_items = [
        "<b>Autoload & Singleton Foundation:</b> Successfully registered core singletons in <code>project.godot</code>: <code>UIManager</code> (scene-based), <code>PoolManager</code>, <code>GameManager</code>, <code>WaveManager</code>, and <code>JoystickLayer</code>.",
        "<b>Virtual Joystick CanvasLayer (Joystick.tscn):</b> Designed and implemented a mobile portrait touch joystick that translates swipe inputs into global vectors.",
        "<b>Auto-Aim Target Scanning:</b> Added <code>Area2D</code> aim scanning to detect the nearest active monsters, enabling automatic weapon tracking essential for portrait gameplay.",
        "<b>Player Sprite & Logic State Machine:</b> Rebuilt <code>PlayerController.gd</code> and <code>Player.tscn</code> character body. Added clean movement, keyboard fallback, and automated state transitions (Walk, Run, Dash, Attack, Hurt, Die).",
        "<b>Core Scene Verification:</b> Rebuilt all 6 primary enemy scenes (Skeleton, Vampire, Werewolf, Ghost, Blood Golem, Plague Doctor) to conform to valid Godot 4.3 <code>.tscn</code> syntax.",
        "<b>Clean Damage Routing:</b> Linked <code>EnemyBase.gd</code> damage routines directly through the player's <code>PlayerStatsComponent</code> instead of bypassing standard handlers.",
        "<b>Interface Upgrades:</b> Refactored the game HUD to automatically hide during selection menus and transition smoothly into active gameplay. Resolved <code>UpgradeShop</code> naming conflicts in the canvas UI layers.",
        "<b>Automated Grok Integration:</b> Completed the Playwright/API synchronization bridge. All design logs are automatically retrieved, compared, and formatted in <code>grok_conversation.md</code>."
    ]
    for item in completed_items:
        story.append(Paragraph(f"• {item}", bullet_style))

    story.append(Spacer(1, 10))

    # Section 3: Where We Are (Current Status)
    story.append(Paragraph("3. Current System Architecture: The Mini-Boss Framework", h1_style))
    story.append(Paragraph(
        "We are proceeding chronologically with <b>Week 2</b> (ranged combat/pooling) and <b>Week 3</b> (progression/upgrade cards) next. "
        "However, our latest synchronization with Grok has yielded the complete codebase blueprints for the <b>Week 4 Mini-Boss System</b> early. "
        "This allows us to review and pre-architect the force-field mechanics, high-stakes arenas, and rare tier rewards before we reach the Week 4 milestone.",
        body_style
    ))
    
    story.append(Paragraph("<b>Mini-Boss Spawning Loop (WaveManager.gd):</b>", h2_style))
    story.append(Paragraph(
        "Spawns a specific mini-boss scene every 10th wave. Spawning a boss automatically scales down regular mob populations "
        "to maintain frame rates. The system registers the boss instance, tracks its health, and triggers a <code>ForceFieldArena</code> node "
        "that locks the player inside a radius around the boss until the entity is defeated.",
        body_style
    ))
    
    story.append(Paragraph("<b>The Four Mythic Mini-Bosses:</b>", h2_style))
    bosses = [
        "<b>Alpha Werewolf (Wave 10):</b> Aggressive pathing, high-speed chase. Triggers a <code>ForceField</code> at 60% and 25% health, gaining 80% damage reduction for 6 seconds.",
        "<b>Vampire Matriarch (Wave 20):</b> Combines fast bat-dash maneuvers with summon calls. Triggers a shield at 50% health, summoning a bat swarm for protection.",
        "<b>Revenant Frankenstein (Wave 30):</b> High-health juggernaut. Triggers a shield at 65% health, amplifying chain lightning capabilities.",
        "<b>Lich High Priest (Wave 40):</b> Ranged summoner/caster. Activates a high-power damage shield at 70% health, spawning waves of skeleton minions."
    ]
    for b in bosses:
        story.append(Paragraph(f"• {b}", bullet_style))

    # Page Break for better readability
    story.append(PageBreak())

    # Section 4: Where We Are Going (Roadmap)
    story.append(Paragraph("4. Strategic Milestone Roadmap (Weeks 2 — 6)", h1_style))
    
    roadmap_items = [
        ("Week 2: Ranged Combat & Pathfinding", [
            "<b>Silver Crossbow:</b> Implement weapon resource parameters (damage, velocity, fire rate templates).",
            "<b>Projectile Pooling:</b> Expand <code>PoolManager</code> to handle silver bolts and impact particle effects to preserve mobile memory.",
            "<b>Smart Pathfinding:</b> Integrate <code>NavigationAgent2D</code> on <code>EnemyBase.gd</code> to bypass walls and layout obstacles intelligently."
        ]),
        ("Week 3: Progression & Drops", [
            "<b>Sinister Upgrades:</b> Design UI upgrade cards (Offensive/Defensive/Utility panels) triggered post-wave clearance.",
            "<b>World Pickups:</b> Implement item drops on monster death (Blood essence, temporary speed boosts, temporary invincibility bubbles)."
        ]),
        ("Week 4: Character Roster & Environments", [
            "<b>Roster Expansion:</b> Add character presets for Elias Voss & Serena Nightshade.",
            "<b>Advanced State Machines:</b> Implement werewolf dash and vampire bat transformations.",
            "<b>Map Development:</b> Build portrait-optimized layouts for the Cathedral, Mansion, and Ruins."
        ]),
        ("Week 5: Polish & Game Juice", [
            "<b>Visual Feedback:</b> Create a camera screenshake shader for impacts.",
            "<b>GPU Particles:</b> Implement GPU-accelerated blood splatters on enemy deaths.",
            "<b>AI Optimizations:</b> Implement visibility-based processing to pause AI routines for entities off-screen."
        ]),
        ("Week 6: Save Systems & Release Preparation", [
            "<b>JSON Serialization:</b> Build local file storage for player upgrades, high-scores, and unlocked lore pages.",
            "<b>Victor Van Helsing:</b> Implement the final premium unlockable character class.",
            "<b>Export Builds:</b> Configure Android APK and iOS project builds for final QA testing."
        ])
    ]

    for week_title, details in roadmap_items:
        story.append(Paragraph(week_title, h2_style))
        for detail in details:
            story.append(Paragraph(detail, bullet_style))
        story.append(Spacer(1, 4))

    # Summary table comparing Completed vs Pending milestones
    summary_data = [
        [Paragraph("<b>Status</b>", cell_hdr_style), Paragraph("<b>Milestone Categories</b>", cell_hdr_style), Paragraph("<b>Tasks</b>", cell_hdr_style)],
        [Paragraph("Completed", badge_completed := ParagraphStyle('bc', parent=bullet_style, textColor=colors.HexColor("#0F5132"))), 
         Paragraph("Autoload System, Mobile Joysticks, Target Scan, Syntax Fixes, Damage Router, HUD toggles, Git/Grok Bridge", body_style), 
         Paragraph("11 Tasks", body_style)],
        [Paragraph("Pending", badge_pending := ParagraphStyle('bp', parent=bullet_style, textColor=colors.HexColor("#664D03"))), 
         Paragraph("Crossbow weapons, Bolt pooling, Smart navigation, Upgrade cards, Pickups, Roster heroes, Boss states, Shaders, Save system, Mobile Export", body_style), 
         Paragraph("17 Tasks", body_style)]
    ]
    
    t_style = [
        ('BACKGROUND', (0,0), (-1,0), burgundy),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('GRID', (0,0), (-1,-1), 0.5, border_grey),
        ('BACKGROUND', (0,1), (0,1), colors.HexColor("#D1E7DD")),
        ('BACKGROUND', (0,2), (0,2), colors.HexColor("#FFF3CD")),
        ('TOPPADDING', (0,0), (-1,-1), 6),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
    ]
    
    roadmap_table = Table(summary_data, colWidths=[70, 364, 70])
    roadmap_table.setStyle(TableStyle(t_style))
    
    story.append(Spacer(1, 10))
    story.append(Paragraph("<b>Roadmap Summary Table:</b>", h2_style))
    story.append(roadmap_table)

    # Build the document
    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"Roadmap Breakdown PDF successfully built: {filename}")


if __name__ == "__main__":
    build_breakdown_pdf()
