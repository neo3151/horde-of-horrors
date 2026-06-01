import glob, re
for f in glob.glob('scripts/**/*.gd', recursive=True):
    with open(f, 'r') as file:
        lines = file.read().splitlines()
    
    out = []
    for line in lines:
        # Match leading spaces
        match = re.match(r'^( +)', line)
        if match:
            spaces = match.group(1)
            # Calculate tabs (round up or assume 4 spaces = 1 tab)
            # If there's a mix of tabs and spaces, this might be tricky,
            # but let's assume we want pure tabs everywhere.
            # If a line starts with tabs AND spaces, we should match ALL leading whitespace
            pass
            
    # Better approach: replace ALL leading whitespace (tabs and spaces) with purely tabs.
    # We can just count the indentation level.
    # 1 tab = 4 spaces.
    
    out2 = []
    for line in lines:
        stripped = line.lstrip(' \t')
        if not stripped:
            out2.append('')
            continue
            
        leading_ws = line[:len(line) - len(stripped)]
        # calculate total spaces
        total_spaces = 0
        for char in leading_ws:
            if char == '\t':
                total_spaces += 4
            else:
                total_spaces += 1
                
        num_tabs = round(total_spaces / 4)
        out2.append('\t' * num_tabs + stripped)
        
    with open(f, 'w') as file:
        file.write('\n'.join(out2) + '\n')
