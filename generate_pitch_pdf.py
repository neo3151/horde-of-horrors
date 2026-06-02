#!/usr/bin/env python3
import os
import sys
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, KeepTogether, Image
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors
from reportlab.pdfgen import canvas

LOGO_PATH = "/home/neo/.gemini/antigravity/scratch/horde-of-horrors/horde-of-horrors-godot/icon.png"
FINANCIAL_CHART_PATH = "/home/neo/.gemini/antigravity/scratch/horde-of-horrors/financial_chart.png"
LTV_CHART_PATH = "/home/neo/.gemini/antigravity/scratch/horde-of-horrors/ltv_chart.png"

def draw_first_page(canvas, doc):
    canvas.saveState()
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(colors.HexColor("#555555"))
    canvas.drawString(54, 45, "Confidential — Horde of Horrors Pitch & Investment Proposal")
    canvas.drawRightString(558, 45, "Page 1")
    
    # Footer line
    canvas.setStrokeColor(colors.HexColor("#C5A059"))
    canvas.setLineWidth(0.5)
    canvas.line(54, 55, 558, 55)
    canvas.restoreState()

def draw_later_pages(canvas, doc):
    canvas.saveState()
    # Header
    canvas.setFont("Helvetica-Bold", 8)
    canvas.setFillColor(colors.HexColor("#6B1724")) # Burgundy
    canvas.drawString(54, 755, "HORDE OF HORRORS — INVESTMENT PROPOSAL & BUSINESS PLAN")
    
    # Header Line
    canvas.setStrokeColor(colors.HexColor("#6B1724"))
    canvas.setLineWidth(1)
    canvas.line(54, 747, 558, 747)
    
    canvas.setStrokeColor(colors.HexColor("#C5A059")) # Old Gold
    canvas.setLineWidth(0.5)
    canvas.line(54, 745, 558, 745)
    
    # Footer
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(colors.HexColor("#555555"))
    canvas.drawString(54, 45, "Confidential — Horde of Horrors Pitch & Investment Proposal")
    canvas.drawRightString(558, 45, f"Page {doc.page}")
    
    # Footer line
    canvas.setStrokeColor(colors.HexColor("#C5A059"))
    canvas.setLineWidth(0.5)
    canvas.line(54, 55, 558, 55)
    canvas.restoreState()


def build_pitch_pdf(filename="horde_of_horrors_pitch.pdf"):
    doc = SimpleDocTemplate(
        filename,
        pagesize=letter,
        leftMargin=54,
        rightMargin=54,
        topMargin=72,
        bottomMargin=72
    )

    styles = getSampleStyleSheet()
    
    # Colors
    burgundy = colors.HexColor("#6B1724")
    gold = colors.HexColor("#C5A059")
    charcoal = colors.HexColor("#2C2C2C")
    light_grey = colors.HexColor("#F8F9FA")
    border_grey = colors.HexColor("#E2E8F0")
    white = colors.white
    
    # Typography Styles
    title_style = ParagraphStyle(
        'DocTitle', parent=styles['Normal'],
        fontName='Times-Bold', fontSize=28, leading=32,
        textColor=burgundy, alignment=1, spaceAfter=8
    )
    
    subtitle_style = ParagraphStyle(
        'DocSubtitle', parent=styles['Normal'],
        fontName='Times-Italic', fontSize=14, leading=16,
        textColor=colors.HexColor("#555555"), alignment=1, spaceAfter=20
    )
    
    metadata_style = ParagraphStyle(
        'DocMetadata', parent=styles['Normal'],
        fontName='Helvetica-Bold', fontSize=9.5, leading=13,
        textColor=charcoal, alignment=1, spaceAfter=2
    )

    h1_style = ParagraphStyle(
        'H1', parent=styles['Normal'],
        fontName='Times-Bold', fontSize=15, leading=18,
        textColor=burgundy, spaceBefore=12, spaceAfter=8,
        keepWithNext=True
    )

    h2_style = ParagraphStyle(
        'H2', parent=styles['Normal'],
        fontName='Helvetica-Bold', fontSize=10.5, leading=13,
        textColor=burgundy, spaceBefore=8, spaceAfter=4,
        keepWithNext=True
    )
    
    body_style = ParagraphStyle(
        'Body', parent=styles['Normal'],
        fontName='Helvetica', fontSize=9.5, leading=13.5,
        textColor=charcoal, spaceAfter=6
    )

    bullet_style = ParagraphStyle(
        'Bullet', parent=body_style,
        leftIndent=15, firstLineIndent=-10, spaceAfter=4
    )

    callout_title = ParagraphStyle(
        'CalloutTitle', parent=styles['Normal'],
        fontName='Helvetica-Bold', fontSize=10, leading=12,
        textColor=burgundy
    )
    
    callout_text = ParagraphStyle(
        'CalloutText', parent=styles['Normal'],
        fontName='Helvetica-Oblique', fontSize=9, leading=12.5,
        textColor=charcoal
    )

    cell_hdr_style = ParagraphStyle(
        'CellHeader', parent=styles['Normal'],
        fontName='Helvetica-Bold', fontSize=9, leading=11,
        textColor=white, alignment=0
    )

    cell_body_style = ParagraphStyle(
        'CellBody', parent=styles['Normal'],
        fontName='Helvetica', fontSize=8, leading=10,
        textColor=charcoal
    )
    
    cell_body_bold = ParagraphStyle(
        'CellBodyBold', parent=cell_body_style,
        fontName='Helvetica-Bold'
    )
    
    badge_completed = ParagraphStyle(
        'BadgeCompleted', parent=cell_body_style,
        textColor=colors.HexColor("#0F5132"), alignment=1
    )
    
    badge_pending = ParagraphStyle(
        'BadgePending', parent=cell_body_style,
        textColor=colors.HexColor("#664D03"), alignment=1
    )
    
    cell_body_loss = ParagraphStyle(
        'CellBodyLoss', parent=cell_body_style,
        textColor=colors.HexColor("#851515")
    )

    story = []

    # ================= PAGE 1: COVER PAGE =================
    story.append(Spacer(1, 40))
    if os.path.exists(LOGO_PATH):
        logo_img = Image(LOGO_PATH, width=110, height=110)
        logo_img.hAlign = 'CENTER'
        story.append(logo_img)
        story.append(Spacer(1, 15))
    
    story.append(Paragraph("HORDE OF HORRORS", title_style))
    story.append(Paragraph("Comprehensive Investment Prospectus & Business Plan", subtitle_style))
    
    # Divider line
    divider = Table([[""]], colWidths=[200])
    divider.setStyle(TableStyle([
        ('LINEBELOW', (0,0), (-1,-1), 1.5, gold),
        ('BOTTOMPADDING', (0,0), (-1,-1), 0),
        ('TOPPADDING', (0,0), (-1,-1), 0),
        ('ALIGN', (0,0), (-1,-1), 'CENTER')
    ]))
    story.append(divider)
    story.append(Spacer(1, 35))
    
    story.append(Paragraph("<b>PROPOSED BY:</b> Antigravity Studios", metadata_style))
    story.append(Paragraph("<b>DATE:</b> June 2026", metadata_style))
    story.append(Paragraph("<b>CONTACT:</b> investment@antigravitystudios.com", metadata_style))
    story.append(Paragraph("<b>VALUATION CAP:</b> $2.5 Million", metadata_style))
    story.append(Paragraph("<b>CONFIDENTIALITY:</b> Strict NDAs Apply", ParagraphStyle('Conf', parent=metadata_style, textColor=colors.HexColor("#851515"))))
    
    story.append(Spacer(1, 60))
    
    summary_box = Table(
        [[
            Paragraph("<b>PROPOSAL HIGHLIGHTS:</b> Seeking a <b>$250,000 Seed Round</b> to fund development expansion, obtain premium 2D character/monster sprite assets, license orchestrations, and run user acquisition campaigns. High-fidelity mechanics (destructible cover, time-survival loops) differentiate the title in the $18 Billion mobile roguelike market.", callout_title)
        ]],
        colWidths=[504]
    )
    summary_box.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#FCFBF9")),
        ('BOX', (0,0), (-1,-1), 1, gold),
        ('PADDING', (0,0), (-1,-1), 10),
        ('ALIGN', (0,0), (-1,-1), 'CENTER')
    ]))
    story.append(summary_box)
    story.append(PageBreak())

    # ================= PAGE 2: BUSINESS STRATEGY & VALUE PROPOSITION =================
    story.append(Paragraph("2. Executive Summary & Value Proposition", h1_style))
    story.append(Paragraph(
        "The mobile action roguelite genre has exploded in recent years, led by pathfinder titles such as <i>Vampire Survivors</i> "
        "and <i>Survivor.io</i>. However, the market faces a growing issue: **formulaic saturation**. "
        "Most current survival games rely on open-field kiting with zero mechanical interaction. "
        "This creates highly repetitive runs that suffer from steep drop-offs in long-term player engagement.",
        body_style
    ))
    story.append(Paragraph(
        "<b>Horde of Horrors</b> introduces a unique solution that transforms standard survivor kiting into a highly tactical combat experience: "
        "a dynamic, destructible cover system paired with interactive environmental obstacles and structured pre-wave briefings. "
        "This creates a tight mechanical feedback loop: instead of simply running away, players must actively navigate from node to node, "
        "using mossy tombstones, ruined stone pillars, and wooden barricades as shields against incoming ranged projectiles.",
        body_style
    ))
    
    # Core Pillars Box
    p_box = Table([
        [Paragraph("<b>Dynamic Cover Mechanics</b>", callout_title), Paragraph("<b>Visual Stack Tech</b>", callout_title)],
        [
            Paragraph("Cover blocks paths and enemy bullets. Cover has health and breaks dynamically, forcing players to adapt and relocate.", callout_text),
            Paragraph("Gothic layered character model rendering. Generates pseudo-3D parallax visual effects at 60 FPS mobile performance.", callout_text)
        ]
    ], colWidths=[252, 252])
    p_box.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), light_grey),
        ('GRID', (0,0), (-1,-1), 0.5, border_grey),
        ('PADDING', (0,0), (-1,-1), 8),
        ('VALIGN', (0,0), (-1,-1), 'TOP')
    ]))
    story.append(p_box)
    story.append(Spacer(1, 8))
    
    story.append(Paragraph("<b>Market Opportunity:</b>", h2_style))
    story.append(Paragraph(
        "By merging the simple, addictive, single-handed controls of a casual roguelite with the atmospheric, premium horror art style "
        "associated with high-end RPG franchises (like <i>Diablo</i> and <i>Castlevania</i>), Horde of Horrors fits a high-value niche. "
        "This positioning targets the mid-core audience that has higher average revenue per paying user (ARPPU) than casual arcade players.",
        body_style
    ))
    story.append(PageBreak())

    # ================= PAGE 3: GAMEPLAY MECHANICS BREAKDOWN =================
    story.append(Paragraph("3. Core Gameplay Mechanics", h1_style))
    
    story.append(Paragraph("<b>A. Pre-Wave Stage Briefing Panel</b>", h2_style))
    story.append(Paragraph(
        "Before each wave begins, the game pauses to show a premium pre-wave briefing panel. "
        "This screen acts as a strategic planning phase, displaying the current environment milestone, Expected Monsters, "
        "contextual survival tips, and a threat rating (💀 to 💀💀💀💀💀). It features smooth zoom-in and fade animations "
        "(0.25s tweens) to establish atmosphere and build player anticipation.",
        body_style
    ))
    
    story.append(Paragraph("<b>B. Destructible Cover Obstacles</b>", h2_style))
    story.append(Paragraph(
        "Cover obstacles (gravestones, pillars, barrels, barricades) spawn dynamically in the level, blocking both player and enemy movement and bullets. "
        "Each has structural health points (default: 150). When hit, they flash red and white. "
        "As health decreases, their sprite modulates toward red (simulating cracking and deterioration). "
        "Upon depletion, they crumble into debris particles, playing a heavy disintegration sound, exposing the player to damage.",
        body_style
    ))
    
    story.append(Paragraph("<b>C. Survival Countdown Loop & Cleansing Light</b>", h2_style))
    story.append(Paragraph(
        "Unlike endless combat loops, normal stages operate on a survival timer (scaling from 30 to 90 seconds). "
        "Enemies spawn infinitely, with spawning rates multiplying by 2.5x during the final 10 seconds. "
        "When the clock hits 0:00, a blinding white screen-flash triggers a 'Holy Light' cleanse, instakilling all normal enemies "
        "and opening the Upgrade Shop. Boss fights occur on multiples of 10 waves and require defeating the boss inside a forcefield arena.",
        body_style
    ))
    
    story.append(Paragraph("<b>D. Roster & Ability Systems</b>", h2_style))
    story.append(Paragraph(
        "Playable characters feature distinct movement stats and unique active abilities. For example, playing as Victor Van Helsing "
        "unlocks the <b>'Holy Stopping Power'</b> active ability. When clicked, it triggers a large radial knockback shockwave to clear "
        "the immediate area, adds +20 flat projectile damage for 4.0 seconds, and tints the character golden. Abilities run on custom cooldown structures.",
        body_style
    ))
    story.append(PageBreak())

    # ================= PAGE 4: TECHNICAL ARCHITECTURE & OPTIMIZATIONS =================
    story.append(Paragraph("4. Technical Architecture & Mobile Optimizations", h1_style))
    story.append(Paragraph(
        "Horde of Horrors is built using **Godot 4.3**, leveraging a highly optimized GDScript architecture designed "
        "specifically to maintain a constant **60 FPS** on mid-range and budget mobile devices. "
        "Our engineering pipeline focuses on heavy memory management and minimizing draw calls:",
        body_style
    ))
    
    tech_points = [
        "<b>Custom Object Pooling (PoolManager.gd):</b> Renders and recycles hundreds of projectiles, impact particles, and blood splatters without garbage collection stutter, keeping memory usage constant and minimizing mobile CPU cycles.",
        "<b>Programmatic Collision Resolution:</b> Instantiated obstacles and players register collision channels programmatically (using dynamic binary mask bit shifts: <code>collision_mask |= 8</code>). This avoids scene-parsing overhead and ensures instant, robust physics resolution.",
        "<b>Decoupled Architecture:</b> Core game systems (UI, Wave Manager, Sound, Character selection) communicate via decoupled, signal-driven singletons (Autoloads), ensuring clean memory teardowns and making codebase extensions simple."
    ]
    for pt in tech_points:
        story.append(Paragraph(f"• {pt}", bullet_style))
        
    story.append(Spacer(1, 10))
    
    # Technical specs table
    specs_data = [
        [Paragraph("<b>Engine / Module</b>", cell_hdr_style), Paragraph("<b>Implementation Details</b>", cell_hdr_style), Paragraph("<b>Performance Target</b>", cell_hdr_style)],
        [Paragraph("Rendering Engine", cell_body_bold), Paragraph("Godot 4.3 (Mobile OpenGL ES 3.0 backend)", cell_body_style), Paragraph("Consistent 60 FPS", cell_body_style)],
        [Paragraph("Memory Management", cell_body_bold), Paragraph("Object pooling for bullets, effects, and damage labels", cell_body_style), Paragraph("< 150MB RAM footprint", cell_body_style)],
        [Paragraph("Pathfinding AI", cell_body_bold), Paragraph("NavigationAgent2D with dynamic obstacle avoidance", cell_body_style), Paragraph("< 1.5ms thread budget", cell_body_style)],
        [Paragraph("Asset Pipeline", cell_body_bold), Paragraph("Black-background transparentized sprite strips", cell_body_style), Paragraph("Minimal VRAM usage", cell_body_style)]
    ]
    specs_table = Table(specs_data, colWidths=[120, 264, 120])
    specs_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), burgundy),
        ('GRID', (0,0), (-1,-1), 0.5, border_grey),
        ('PADDING', (0,0), (-1,-1), 6),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE')
    ]))
    story.append(specs_table)
    story.append(PageBreak())

    # ================= PAGE 5: COMPETITOR LANDSCAPE & COMPETITIVE EDGE =================
    story.append(Paragraph("5. Competitor Landscape & Competitive Edge", h1_style))
    story.append(Paragraph(
        "Horde of Horrors sits at the intersection of casual survivor mechanics and mid-core dark gothic RPG themes. "
        "Below is a direct comparison of Horde of Horrors against the current leading competitors in the mobile action space:",
        body_style
    ))
    
    comp_data = [
        [
            Paragraph("<b>Feature Metric</b>", cell_hdr_style),
            Paragraph("<b>Horde of Horrors</b>", cell_hdr_style),
            Paragraph("<b>Survivor.io</b>", cell_hdr_style),
            Paragraph("<b>Vampire Survivors</b>", cell_hdr_style),
            Paragraph("<b>Zombie.io</b>", cell_hdr_style)
        ],
        [
            Paragraph("<b>Tactical Cover</b>", cell_body_bold),
            Paragraph("Yes (Dynamic & Destructible)", cell_body_style),
            Paragraph("No", cell_body_style),
            Paragraph("No", cell_body_style),
            Paragraph("No (Static obstacles only)", cell_body_style)
        ],
        [
            Paragraph("<b>Art Direction</b>", cell_body_bold),
            Paragraph("Dark Gothic Horror", cell_body_style),
            Paragraph("Casual Cartoon", cell_body_style),
            Paragraph("Retro 8-Bit Pixel", cell_body_style),
            Paragraph("Casual Cartoon / Sci-Fi", cell_body_style)
        ],
        [
            Paragraph("<b>Wave Objective</b>", cell_body_bold),
            Paragraph("Survival timer + Boss milestones", cell_body_style),
            Paragraph("Survival timer", cell_body_style),
            Paragraph("Survival timer (30 mins)", cell_body_style),
            Paragraph("Slay-all / Wave clearance", cell_body_style)
        ],
        [
            Paragraph("<b>Active Skills</b>", cell_body_bold),
            Paragraph("Yes (Cooldown active buttons)", cell_body_style),
            Paragraph("No (Passive stats only)", cell_body_style),
            Paragraph("No (Passive stats only)", cell_body_style),
            Paragraph("No (Auto-activated only)", cell_body_style)
        ],
        [
            Paragraph("<b>Rendering Speed</b>", cell_body_bold),
            Paragraph("Lightweight Godot (60 FPS)", cell_body_style),
            Paragraph("Unity (Heavier RAM)", cell_body_style),
            Paragraph("Phaser / Custom C++", cell_body_style),
            Paragraph("Unity (Very Heavy)", cell_body_style)
        ]
    ]
    comp_table = Table(comp_data, colWidths=[110, 114, 90, 100, 90])
    comp_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), burgundy),
        ('GRID', (0,0), (-1,-1), 0.5, border_grey),
        ('PADDING', (0,0), (-1,-1), 6),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('BACKGROUND', (1,1), (1,-1), colors.HexColor("#FCFBF9"))
    ]))
    story.append(comp_table)
    
    story.append(Spacer(1, 10))
    story.append(Paragraph("<b>Our Competitive Advantage:</b>", h2_style))
    story.append(Paragraph(
        "By focusing on tactical positioning (obstacles) and active player agency (cooldown abilities), Horde of Horrors "
        "solves the 'hands-off' passive gameplay issue that plagues competitors. Players are constantly engaged, "
        "reacting to crumbling barricades and timing ultimate abilities. This directly translates into higher player "
        "engagement and improved Day 7 / Day 30 retention metrics.",
        body_style
    ))
    story.append(PageBreak())

    # ================= PAGE 6: USER ACQUISITION & COHORT RETENTION =================
    story.append(Paragraph("6. User Acquisition & Cohort Retention Projections", h1_style))
    story.append(Paragraph(
        "Our commercialization plan utilizes organic visual loops to drive down paid marketing costs. "
        "Because our 'Stack Sprite' technology produces a striking, high-detail pseudo-3D look, short gameplay clips "
        "naturally capture high engagement on visual social networks (TikTok, Shorts, and Reels). "
        "This organic flywheel is paired with paid performance marketing optimized for a low Cost Per Install (CPI).",
        body_style
    ))
    
    # Embedded LTV vs CPI Chart
    if os.path.exists(LTV_CHART_PATH):
        ltv_img = Image(LTV_CHART_PATH, width=320, height=200)
        ltv_img.hAlign = 'CENTER'
        story.append(ltv_img)
        story.append(Spacer(1, 8))
        
    story.append(Paragraph("<b>Target Retention and Unit Economics:</b>", h2_style))
    story.append(Paragraph(
        "As modeled in the cohort chart above, our base target is to stabilize Cost Per Install (CPI) around **$1.45 - $1.55** "
        "during soft launch, and aggressively scale Customer Lifetime Value (LTV) to **$2.20 by Month 3** and **$4.50 by Month 12** "
        "through progression updates, cosmetics, and seasonal content. Our retention targets are: "
        "**Day 1: 42%**, **Day 7: 18%**, and **Day 30: 6%**.",
        body_style
    ))
    story.append(PageBreak())

    # ================= PAGE 7: FINANCIAL PROJECTIONS =================
    story.append(Paragraph("7. 3-Year Financial Projections", h1_style))
    story.append(Paragraph(
        "Our financial model assumes a soft launch in Q1 Year 1, followed by global roll-out in Q3 Year 1. "
        "Operating costs are kept low by utilizing Godot's lightweight open-source licensing structure (no engine royalties), "
        "allowing us to direct a higher percentage of seed funds toward marketing and asset production:",
        body_style
    ))
    
    # Embedded Financial Chart
    if os.path.exists(FINANCIAL_CHART_PATH):
        fin_img = Image(FINANCIAL_CHART_PATH, width=320, height=200)
        fin_img.hAlign = 'CENTER'
        story.append(fin_img)
        story.append(Spacer(1, 8))
        
    # Financial Table
    fin_data = [
        [Paragraph("<b>Metric Projections (USD)</b>", cell_hdr_style), Paragraph("<b>Year 1 (Soft)</b>", cell_hdr_style), Paragraph("<b>Year 2 (Global)</b>", cell_hdr_style), Paragraph("<b>Year 3 (Live-Ops)</b>", cell_hdr_style)],
        [Paragraph("Active Player Cohort (MAUs)", cell_body_bold), Paragraph("150,000", cell_body_style), Paragraph("1,800,000", cell_body_style), Paragraph("4,200,000", cell_body_style)],
        [Paragraph("Gross Revenue Projections", cell_body_bold), Paragraph("$120,000", cell_body_style), Paragraph("$1,450,000", cell_body_style), Paragraph("$3,800,000", cell_body_style)],
        [Paragraph("Marketing & UA Spend", cell_body_bold), Paragraph("$80,000", cell_body_style), Paragraph("$450,000", cell_body_style), Paragraph("$1,000,000", cell_body_style)],
        [Paragraph("Development & Server Cost", cell_body_bold), Paragraph("$150,000", cell_body_style), Paragraph("$350,000", cell_body_style), Paragraph("$600,000", cell_body_style)],
        [Paragraph("Projected Net Profit", cell_body_bold), Paragraph("-$110,000", cell_body_loss), Paragraph("$650,000", cell_body_style), Paragraph("$2,200,000", cell_body_style)]
    ]
    fin_table = Table(fin_data, colWidths=[180, 108, 108, 108])
    fin_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), burgundy),
        ('GRID', (0,0), (-1,-1), 0.5, border_grey),
        ('PADDING', (0,0), (-1,-1), 6),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE')
    ]))
    story.append(fin_table)
    story.append(PageBreak())

    # ================= PAGE 8: MONETIZATION & IN-GAME ECONOMY =================
    story.append(Paragraph("8. Monetization & In-Game Economy", h1_style))
    story.append(Paragraph(
        "Horde of Horrors implements a balanced, high-conversion hybrid economy centered on two main progression paths:",
        body_style
    ))
    
    mon_details = [
        "<b>A. Double Currency Loop:</b> Players gather **Gold** (spent in-game between waves for immediate, random card upgrades in the Upgrade Shop) and **Blood Essence** (a persistent meta-currency dropped by boss monsters, used between runs to unlock permanent skill trees and unlock new characters).",
        "<b>B. Rewarded Video Ad Placements:</b> Integrated to align player incentives. Watching a short video allows the player to double their wave gold, obtain a second shop re-roll, or revive once per run. This creates high daily active user (DAU) conversion without degrading premium gameplay value.",
        "<b>C. Premium Purchases & Hero Unlocks:</b> Premium characters (like specific specialized classes of Victor Van Helsing or Elias Voss) are unlocked using paid gems or direct purchases. Vanity microtransactions (cosmetic character card animations, golden shockwave weapon effects) appeal to highly engaged players.",
        "<b>D. Battle Passes (Gothic Seasons):</b> Generates recurring monthly revenue. Free and Premium tiers reward players with unique character profile skulls, lore journals, and exclusive skins as they complete weekly survival challenges."
    ]
    for m in mon_details:
        story.append(Paragraph(m, bullet_style))
        story.append(Spacer(1, 4))
        
    story.append(Spacer(1, 10))
    story.append(Paragraph("<b>Economy Design Table:</b>", h2_style))
    
    econ_data = [
        [Paragraph("<b>Item Category</b>", cell_hdr_style), Paragraph("<b>Purchase Method</b>", cell_hdr_style), Paragraph("<b>Gameplay Impact</b>", cell_hdr_style), Paragraph("<b>Sinks / Usage</b>", cell_hdr_style)],
        [Paragraph("Character Cards", cell_body_bold), Paragraph("IAP / Meta-Essence", cell_body_style), Paragraph("New active skills & base stats", cell_body_style), Paragraph("Unlock playable roster", cell_body_style)],
        [Paragraph("Gold Currency", cell_body_bold), Paragraph("Gameplay drop / Ads", cell_body_style), Paragraph("Temporary wave buffs", cell_body_style), Paragraph("Upgrade Shop purchases", cell_body_style)],
        [Paragraph("Blood Essence", cell_body_bold), Paragraph("Boss drop / Gem pack", cell_body_style), Paragraph("Permanent stat progression", cell_body_style), Paragraph("Talent tree upgrades", cell_body_style)],
        [Paragraph("Cosmetic Skins", cell_body_bold), Paragraph("Battle Pass / Gems", cell_body_style), Paragraph("Purely visual flair", cell_body_style), Paragraph("Character customization", cell_body_style)]
    ]
    econ_table = Table(econ_data, colWidths=[110, 114, 140, 140])
    econ_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), burgundy),
        ('GRID', (0,0), (-1,-1), 0.5, border_grey),
        ('PADDING', (0,0), (-1,-1), 6),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE')
    ]))
    story.append(econ_table)
    story.append(PageBreak())

    # ================= PAGE 9: ROADMAP & MILESTONES =================
    story.append(Paragraph("9. Operational Roadmap & Milestones", h1_style))
    story.append(Paragraph(
        "Our development pipeline operates in two-week sprints. The core engine is established, and we are moving "
        "rapidly through subsequent developmental stages leading to public launch. The detailed roadmap below outlines our timeline:",
        body_style
    ))
    
    roadmap_items = [
        "<b>Phase 1: Foundation (Weeks 1-2):</b> Rebuild mobile virtual joystick touch inputs, aim scanners, enemy scene hierarchies, and player character controller logic. <i>(Status: 100% Completed)</i>",
        "<b>Phase 2: Core Loop & Cover (Weeks 3-4):</b> Implement destructible cover obstacles, dynamically scale sprite bounds, update timer survival countdowns, and build the pre-wave briefing panel. <i>(Status: 100% Completed)</i>",
        "<b>Phase 3: Ranged Combat & Pooling (Weeks 5-6):</b> Implement Silver Crossbow resource parameters, projectile pooling structures, and navigation pathfinding agent routines.",
        "<b>Phase 4: Progression Mechanics (Weeks 7-8):</b> Integrate Sinister Card Upgrade menu systems, drop pickups (blood essence, speed buffers, shield nodes), and character selection panels.",
        "<b>Phase 5: Hero Expansion & Content (Weeks 9-10):</b> Build maps for Cathedral and Ruined Castle, implement werewolf charge/dash AI, and add Elias and Serena character assets.",
        "<b>Phase 6: Audio & Export (Weeks 11-12):</b> Add camera screenshake, blood particles, JSON save states, gothic background score, and export Android APK/iOS IPA packages for soft launch."
    ]
    for rd in roadmap_items:
        story.append(Paragraph(f"• {rd}", bullet_style))
        story.append(Spacer(1, 4))
        
    story.append(Spacer(1, 10))
    story.append(Paragraph("<b>Milestone Roadmap Summary:</b>", h2_style))
    
    r_data = [
        [Paragraph("<b>Milestone Category</b>", cell_hdr_style), Paragraph("<b>Key Features Built</b>", cell_hdr_style), Paragraph("<b>Current Status</b>", cell_hdr_style)],
        [Paragraph("Core Mechanics & Controls", cell_body_bold), Paragraph("Joystick, Auto-aim, State machines, Vector clamps", cell_body_style), Paragraph("COMPLETED", badge_completed)],
        [Paragraph("Cover & Timer Survival", cell_body_bold), Paragraph("Destructible obstacles, Timer loops, Briefing panels", cell_body_style), Paragraph("COMPLETED", badge_completed)],
        [Paragraph("Weapons & Pathfinding", cell_body_bold), Paragraph("Crossbow weapon, Projectile pooling, NavAgent2D pathing", cell_body_style), Paragraph("PENDING", badge_pending)],
        [Paragraph("Meta-progression", cell_body_bold), Paragraph("Upgrade cards, drop essence pickups, selection menu", cell_body_style), Paragraph("PENDING", badge_pending)],
        [Paragraph("Saves & Audio", cell_body_bold), Paragraph("JSON serializations, screenshake, particles, music, export", cell_body_style), Paragraph("PENDING", badge_pending)]
    ]
    r_table = Table(r_data, colWidths=[150, 264, 90])
    r_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), burgundy),
        ('GRID', (0,0), (-1,-1), 0.5, border_grey),
        ('BACKGROUND', (2,1), (2,2), colors.HexColor("#D1E7DD")),
        ('BACKGROUND', (2,3), (2,5), colors.HexColor("#FFF3CD")),
        ('PADDING', (0,0), (-1,-1), 6),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE')
    ]))
    story.append(r_table)
    story.append(PageBreak())

    # ================= PAGE 10: INVESTMENT OPPORTUNITY & USE OF FUNDS =================
    story.append(Paragraph("10. Investment Offering & Use of Funds", h1_style))
    story.append(Paragraph(
        "Antigravity Studios is offering a **$250,000 Seed Round** at a **$2.5 Million Valuation Cap** "
        "via a Simple Agreement for Future Equity (SAFE). This round will fully fund the development team through "
        "the Phase 6 release milestone, purchase high-quality character assets, and establish initial user acquisition traction:",
        body_style
    ))
    
    story.append(Spacer(1, 10))
    
    # Funding allocation table
    funding_data = [
        [Paragraph("<b>Category Allocation</b>", cell_hdr_style), Paragraph("<b>Percentage</b>", cell_hdr_style), Paragraph("<b>Funding Amount</b>", cell_hdr_style), Paragraph("<b>Strategic Objective Deliverable</b>", cell_hdr_style)],
        [Paragraph("Game Client & Server Engineering", cell_body_bold), Paragraph("45%", cell_body_style), Paragraph("$112,500", cell_body_style), Paragraph("Godot 4.3 optimization, server database saving.", cell_body_style)],
        [Paragraph("Custom 2D Asset Procurement", cell_body_bold), Paragraph("25%", cell_body_style), Paragraph("$62,500", cell_body_style), Paragraph("Hand-drawn stacked character/monster sprite strips.", cell_body_style)],
        [Paragraph("Soft-Launch User Acquisition", cell_body_bold), Paragraph("20%", cell_body_style), Paragraph("$50,000", cell_body_style), Paragraph("Targeted CPI testing and acquisition funnel tuning.", cell_body_style)],
        [Paragraph("Operational Overheads & Legal", cell_body_bold), Paragraph("10%", cell_body_style), Paragraph("$25,000", cell_body_style), Paragraph("Corporate filings, entity maintenance, NDA contracts.", cell_body_style)]
    ]
    funding_table = Table(funding_data, colWidths=[150, 70, 90, 194])
    funding_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), burgundy),
        ('GRID', (0,0), (-1,-1), 0.5, border_grey),
        ('PADDING', (0,0), (-1,-1), 8),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE')
    ]))
    story.append(funding_table)
    
    story.append(Spacer(1, 20))
    story.append(Paragraph("<b>Expected Returns & Project Exit Strategy:</b>", h2_style))
    story.append(Paragraph(
        "By focusing on strong initial monetization and organic acquisition visual loops, we project achieving "
        "profitability within 4 months of the global launch. The exit strategy for seed investors is focused on a Series A "
        "buyout option or strategic acquisition by a larger mobile publisher in Q4 2027.",
        body_style
    ))

    # Build the document
    doc.build(story, onFirstPage=draw_first_page, onLaterPages=draw_later_pages)
    print(f"Expanded 10-page Business Plan PDF successfully built: {filename}")


if __name__ == "__main__":
    build_pitch_pdf()
