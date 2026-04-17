## Product Design Directory Structure

All product design documents are maintained under `<prd-dir>/`:

```
<root-session-dir>/
├── prd/                                 # Product design documents (<prd-dir>)
│   ├── overview.md                      # Product overview: positioning, target users, core value proposition
│   ├── dictionaries/                    # Business enums and constant definitions
│   │   ├── dictionaries.md             # Overview of all dictionary groups
│   │   └── <business-group>/
│   │       └── dictionary-<dictionary-name>.md    # Individual dictionary/enum definition
│   ├── models/                          # Models, attributes, states & transitions
│   │   ├── models.md                    # Overview of business groups and model files
│   │   └── <business-group>/
│   │       ├── models-<business-group>.md         # Overview of modules and model files under this business group
│   │       └── <module>/
│   │           └── model-<model-name>.md
│   ├── procedures/                      # Processes & rules
│   │   ├── procedures.md               # Overview of business groups and procedure files
│   │   └── <business-group>/
│   │       ├── procedures-<business-group>.md     # Overview of modules and procedure files under this business group
│   │       └── <module>/
│   │           └── procedure-<procedure-name>.md
│   ├── architecture/                    # Product architecture
│   │   ├── architecture.md             # Overall architecture overview (business modules)
│   │   └── roles.md                    # System roles & permissions
│   └── applications/                    # Applications
│       └── <app-type>/                  # e.g., wxa, app, h5, web-admin, desktop, etc.
│           ├── application-<app-type>.md           # Overall page framework
│           └── pages/
│               ├── pages-<application-name>.md    # Overview of business groups and page files
│               └── <business-group>/
│                   ├── pages-<business-group>.md  # Overview of modules and page files under this business group
│                   └── <module>/
│                       ├── pages-module-<module-name>.md  # Overview of page files under this module
│                       └── <NNN>-<page-name>.md
└── changes/    # Change records (<dev-session-dir>)
    └── <YYYY>/
        └── <MM>/
            └── <DD>/
                └── <YYYY-MM-DD-NNN-req-name>/
                    ├── requirement-raw.md
                    └── requirement.md
```
