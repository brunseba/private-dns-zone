// Mermaid configuration for BIND DNS documentation

// Initialize Mermaid with custom configuration
document.addEventListener('DOMContentLoaded', function() {
    // Check if mermaid is loaded
    if (typeof mermaid !== 'undefined') {
        // Configure Mermaid
        mermaid.initialize({
            startOnLoad: true,
            theme: 'default',
            themeVariables: {
                primaryColor: '#2196f3',
                primaryTextColor: '#ffffff',
                primaryBorderColor: '#1976d2',
                lineColor: '#757575',
                secondaryColor: '#ff9800',
                tertiaryColor: '#4caf50',
                background: '#ffffff',
                mainBkg: '#ffffff',
                secondBkg: '#f5f5f5',
                tertiaryBkg: '#e8f5e8'
            },
            flowchart: {
                useMaxWidth: true,
                htmlLabels: true,
                curve: 'basis'
            },
            sequence: {
                diagramMarginX: 50,
                diagramMarginY: 10,
                actorMargin: 50,
                width: 150,
                height: 65,
                boxMargin: 10,
                boxTextMargin: 5,
                noteMargin: 10,
                messageMargin: 35,
                mirrorActors: true,
                bottomMarginAdj: 1,
                useMaxWidth: true,
                rightAngles: false,
                showSequenceNumbers: false
            },
            gantt: {
                useMaxWidth: true,
                barHeight: 20,
                fontSize: 11,
                fontFamily: '"Open Sans", sans-serif',
                numberSectionStyles: 4,
                axisFormat: '%Y-%m-%d'
            },
            state: {
                useMaxWidth: true
            },
            pie: {
                useMaxWidth: true
            },
            git: {
                useMaxWidth: true,
                mainBranchName: 'main'
            }
        });

        // Handle theme switching for dark mode
        const observer = new MutationObserver(function(mutations) {
            mutations.forEach(function(mutation) {
                if (mutation.type === 'attributes' && mutation.attributeName === 'data-md-color-scheme') {
                    const scheme = document.body.getAttribute('data-md-color-scheme');
                    
                    if (scheme === 'slate') {
                        // Dark theme configuration
                        mermaid.initialize({
                            theme: 'dark',
                            themeVariables: {
                                primaryColor: '#90caf9',
                                primaryTextColor: '#000000',
                                primaryBorderColor: '#64b5f6',
                                lineColor: '#bdbdbd',
                                secondaryColor: '#ffcc80',
                                tertiaryColor: '#a5d6a7',
                                background: '#121212',
                                mainBkg: '#1e1e1e',
                                secondBkg: '#2d2d2d',
                                tertiaryBkg: '#1b5e20',
                                textColor: '#ffffff',
                                darkTextColor: '#ffffff'
                            }
                        });
                    } else {
                        // Light theme configuration
                        mermaid.initialize({
                            theme: 'default',
                            themeVariables: {
                                primaryColor: '#2196f3',
                                primaryTextColor: '#ffffff',
                                primaryBorderColor: '#1976d2',
                                lineColor: '#757575',
                                secondaryColor: '#ff9800',
                                tertiaryColor: '#4caf50',
                                background: '#ffffff',
                                mainBkg: '#ffffff',
                                secondBkg: '#f5f5f5',
                                tertiaryBkg: '#e8f5e8'
                            }
                        });
                    }
                    
                    // Re-render all diagrams
                    const diagrams = document.querySelectorAll('.mermaid');
                    diagrams.forEach(function(diagram, index) {
                        const diagramId = 'mermaid-' + index;
                        diagram.id = diagramId;
                        diagram.innerHTML = diagram.getAttribute('data-original') || diagram.innerHTML;
                        if (!diagram.getAttribute('data-original')) {
                            diagram.setAttribute('data-original', diagram.innerHTML);
                        }
                        mermaid.init(undefined, diagram);
                    });
                }
            });
        });

        // Start observing
        observer.observe(document.body, {
            attributes: true,
            attributeFilter: ['data-md-color-scheme']
        });

        // Store original diagram content for re-rendering
        document.querySelectorAll('.mermaid').forEach(function(diagram) {
            if (!diagram.getAttribute('data-original')) {
                diagram.setAttribute('data-original', diagram.innerHTML);
            }
        });
    }
});

// Add custom CSS for better Mermaid integration
const style = document.createElement('style');
style.textContent = `
    .mermaid {
        text-align: center;
        margin: 1em 0;
        overflow-x: auto;
    }
    
    .mermaid svg {
        max-width: 100%;
        height: auto;
    }
    
    /* Custom styling for DNS-specific diagrams */
    .mermaid .node rect,
    .mermaid .node circle,
    .mermaid .node ellipse,
    .mermaid .node polygon {
        stroke-width: 2px;
    }
    
    .mermaid .edgePath .path {
        stroke-width: 2px;
    }
    
    .mermaid .cluster rect {
        fill: rgba(33, 150, 243, 0.1);
        stroke: #2196f3;
        stroke-width: 2px;
        rx: 8px;
        ry: 8px;
    }
    
    /* Sequence diagram customization */
    .mermaid .actor {
        fill: #2196f3;
        stroke: #1976d2;
        stroke-width: 2px;
    }
    
    .mermaid .actor-line {
        stroke: #757575;
        stroke-width: 1px;
        stroke-dasharray: 3,3;
    }
    
    .mermaid .messageLine0,
    .mermaid .messageLine1 {
        stroke: #1976d2;
        stroke-width: 2px;
    }
    
    .mermaid .messageText {
        fill: #333;
        font-family: 'Roboto', sans-serif;
        font-size: 12px;
    }
    
    /* Gantt chart customization */
    .mermaid .section0,
    .mermaid .section1,
    .mermaid .section2,
    .mermaid .section3 {
        fill: #2196f3;
        fill-opacity: 0.8;
    }
    
    .mermaid .cScale0,
    .mermaid .cScale1,
    .mermaid .cScale2 {
        fill: #ff9800;
    }
    
    /* State diagram customization */
    .mermaid .state-start {
        fill: #4caf50;
        stroke: #388e3c;
    }
    
    .mermaid .state-end {
        fill: #f44336;
        stroke: #d32f2f;
    }
    
    .mermaid .state-note {
        fill: #fff3e0;
        stroke: #ff9800;
    }
    
    /* Dark mode adjustments */
    [data-md-color-scheme="slate"] .mermaid .messageText {
        fill: #ffffff;
    }
    
    [data-md-color-scheme="slate"] .mermaid .cluster rect {
        fill: rgba(144, 202, 249, 0.1);
        stroke: #90caf9;
    }
    
    [data-md-color-scheme="slate"] .mermaid .actor {
        fill: #90caf9;
        stroke: #64b5f6;
    }
    
    [data-md-color-scheme="slate"] .mermaid .actor-line {
        stroke: #bdbdbd;
    }
    
    [data-md-color-scheme="slate"] .mermaid .messageLine0,
    [data-md-color-scheme="slate"] .mermaid .messageLine1 {
        stroke: #64b5f6;
    }
`;
document.head.appendChild(style);
