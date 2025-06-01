# 🚀 Cursor Extensions Setup Guide

## 📋 Quick Setup

When you open this project in Cursor, you should see a notification asking if you want to install the recommended extensions. Click **"Install All"** to automatically install all the essential extensions for this project.

If you don't see the notification, follow the manual steps below.

## 🛠️ Essential Extensions (Auto-Install)

These extensions are defined in `.vscode/extensions.json` and will be automatically recommended:

### **Core Development (Must Have)**
- ✅ **Python** (ms-python.python) - Python language support
- ✅ **Pylance** (ms-python.vscode-pylance) - Advanced Python IntelliSense  
- ✅ **Black Formatter** (ms-python.black-formatter) - Python code formatting
- ✅ **isort** (ms-python.isort) - Python import organization
- ✅ **Flake8** (ms-python.flake8) - Python linting

### **Frontend Development**
- ✅ **ES7+ React/Redux Snippets** (dsznajder.es7-react-js-snippets) - React code snippets
- ✅ **ESLint** (dbaeumer.vscode-eslint) - JavaScript/TypeScript linting
- ✅ **Prettier** (esbenp.prettier-vscode) - Code formatting

### **Infrastructure & DevOps**
- ✅ **HashiCorp Terraform** (hashicorp.terraform) - Terraform language support
- ✅ **Docker** (ms-azuretools.vscode-docker) - Docker integration
- ✅ **YAML** (redhat.vscode-yaml) - YAML syntax support
- ✅ **GitHub Actions** (github.vscode-github-actions) - CI/CD workflow support

### **Database & API**
- ✅ **PostgreSQL** (ms-ossdata.vscode-postgresql) - Database management
- ✅ **Thunder Client** (rangav.vscode-thunder-client) - API testing

### **Git & Collaboration**
- ✅ **GitLens** (eamodio.gitlens) - Enhanced Git capabilities
- ✅ **GitHub Pull Requests** (github.vscode-pull-request-github) - PR integration

### **UI & Productivity**
- ✅ **Material Icon Theme** (pkief.material-icon-theme) - Better file icons
- ✅ **Todo Tree** (gruntfuggly.todo-tree) - TODO/FIXME highlighting
- ✅ **Azure Tools** (ms-vscode.vscode-node-azure-pack) - Azure integration

## 🔧 Manual Installation

If the auto-install doesn't work, install manually:

### Method 1: Command Palette
1. Press `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows/Linux)
2. Type "Extensions: Install Extensions"
3. Search for each extension by name or ID
4. Click "Install"

### Method 2: Extensions View
1. Click the Extensions icon in the sidebar (⬜ icon)
2. Search for each extension
3. Click "Install"

### Method 3: One-Click Install Links
Click these links to install directly:
- [Python](vscode:extension/ms-python.python)
- [Pylance](vscode:extension/ms-python.vscode-pylance)
- [Black Formatter](vscode:extension/ms-python.black-formatter)
- [ESLint](vscode:extension/dbaeumer.vscode-eslint)
- [Terraform](vscode:extension/hashicorp.terraform)
- [Docker](vscode:extension/ms-azuretools.vscode-docker)
- [GitLens](vscode:extension/eamodio.gitlens)

## ⚙️ Configuration Applied

The workspace already includes optimized settings in `.vscode/settings.json`:

### **Python Configuration**
- ✅ Virtual environment auto-detection: `./backend/venv/bin/python`
- ✅ Black formatting on save
- ✅ Flake8 linting enabled
- ✅ Import sorting with isort

### **TypeScript/React Configuration**  
- ✅ ESLint auto-fix on save
- ✅ Relative import preferences
- ✅ Prettier formatting

### **Terraform Configuration**
- ✅ Validation on save
- ✅ Auto-completion for required fields

### **General Settings**
- ✅ Format on save enabled
- ✅ Auto-organize imports
- ✅ File nesting for related files
- ✅ Optimized search exclusions

## 🎯 Available Tasks

Press `Cmd+Shift+P` → "Tasks: Run Task" to access these pre-configured tasks:

- **Start Backend Server** - Launch FastAPI with fallback LLM
- **Start Frontend Dev Server** - Launch React dev server  
- **Run Backend Tests** - Execute Python tests with pytest
- **Run Frontend Tests** - Execute React/TypeScript tests
- **Format Backend Code** - Run Black + isort formatting
- **Format Frontend Code** - Run ESLint auto-fix
- **Terraform Plan** - Preview infrastructure changes
- **Docker Build Backend** - Build backend container
- **Install All Dependencies** - Install Python + Node dependencies

## 🐛 Debug Configurations

Press `F5` or go to Run & Debug panel for these configurations:

- **Python: FastAPI Backend** - Debug the backend server
- **Python: Current File** - Debug any Python file
- **Python: Backend Tests** - Debug pytest tests  
- **Attach to Docker Backend** - Debug containerized backend

## 🔥 Pro Tips

### **Keyboard Shortcuts**
- `Cmd+Shift+P`: Command palette
- `Cmd+P`: Quick file search
- `Cmd+Shift+F`: Global search
- `F5`: Start debugging
- `Cmd+Shift+\``: Go to matching bracket
- `Cmd+/`: Toggle line comment

### **Python Development**
- Use `# TODO:` or `# FIXME:` - Todo Tree will highlight them
- Type `import` and let Pylance auto-complete
- Use `Cmd+.` for quick fixes and refactoring

### **React Development**  
- Type `rafce` for React arrow function component
- Type `useState` for React hooks snippets
- Use `Cmd+.` for ESLint quick fixes

### **Git Integration**
- GitLens shows blame info inline
- Use Source Control panel for staging
- GitHub integration for PRs and issues

## 🎨 Customization

### **Theme & Icons**
The workspace uses Material Icon Theme. To change:
1. `Cmd+Shift+P` → "Preferences: Color Theme"
2. `Cmd+Shift+P` → "Preferences: File Icon Theme"

### **Personal Settings**
Create `.vscode/settings_personal.json` for your personal preferences (this file is gitignored).

## 🆘 Troubleshooting

### **Python Extension Issues**
1. Check Python interpreter: `Cmd+Shift+P` → "Python: Select Interpreter"
2. Should point to: `./backend/venv/bin/python`

### **ESLint Not Working**
1. Ensure you're in the frontend directory
2. Run: `cd frontend && npm install`

### **Terraform Extension Issues**
1. Install Terraform CLI: `brew install terraform`
2. Restart Cursor

### **Extension Not Loading**
1. Disable and re-enable the extension
2. Reload window: `Cmd+Shift+P` → "Developer: Reload Window"

## 🚀 Ready to Code!

With all extensions installed and configured, you now have:
- ✅ Full-stack development environment
- ✅ Intelligent code completion and error detection  
- ✅ Automated formatting and linting
- ✅ Integrated debugging capabilities
- ✅ Git and GitHub integration
- ✅ Infrastructure as Code support
- ✅ Database and API tools

Happy coding with your supercharged Cursor setup! 🎉 