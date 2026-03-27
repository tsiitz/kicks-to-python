# KICKS/COBOL to Python Conversion

> **A complete, working example of modernizing CICS/COBOL applications to Python web applications**

## 🎯 Overview

This project demonstrates the full conversion of **Doug Lowe's classic CICS sample application suite** from KICKS/COBOL running on MVS 3.8J to a modern Python Flask web application.

### What You Get

✅ **Working Python/Flask Application** - Run it immediately  
✅ **Original COBOL Source Code** - See the before and after  
✅ **Complete Documentation** - 60+ page conversion guide  
✅ **Real Production Patterns** - Not just theory  

---

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/YOUR-USERNAME/kicks-to-python.git
cd kicks-to-python

# Install and run
pip install -r requirements.txt
python app.py

# Open http://localhost:5000
```

**Sample Customer Numbers:** 400001, 400002, 400003, 400004, 400005

---

## 📚 Documentation

### Getting Started

- [**Quick Start Guide**](https://github.com/YOUR-USERNAME/kicks-to-python/blob/main/README.md#-quick-start) - Get running in 5 minutes
- [**GitHub Upload Instructions**](https://github.com/YOUR-USERNAME/kicks-to-python/blob/main/GITHUB_UPLOAD_INSTRUCTIONS.md) - Detailed setup instructions
- [**Quick Reference**](https://github.com/YOUR-USERNAME/kicks-to-python/blob/main/QUICK_REFERENCE.md) - Command cheat sheet

### Conversion Guide

- [**Complete Conversion Guide**](https://github.com/YOUR-USERNAME/kicks-to-python/blob/main/KICKS_TO_PYTHON_CONVERSION_GUIDE.md) - Full 60+ page guide covering all patterns
  - Architecture decisions
  - Data migration strategies (VSAM to SQL)
  - Program conversion patterns (COBOL to Python)
  - Screen conversion (BMS maps to HTML)
  - Implementation roadmap

### Reference

- [**Python Application README**](https://github.com/YOUR-USERNAME/kicks-to-python/blob/main/README.md) - Application documentation
- [**COBOL Source Code README**](https://github.com/YOUR-USERNAME/kicks-to-python/blob/main/cobol-source/README.md) - Original program documentation
- [**GitHub Repository**](https://github.com/YOUR-USERNAME/kicks-to-python) - View all source code

---

## 🔑 Key Features

### Converted Programs

| Transaction | Original COBOL | Python Route | Description |
|-------------|----------------|--------------|-------------|
| **INQ1** | CUSTINQ1 | `/customer/inquiry` | Basic customer inquiry |
| **INQ2** | CUSTINQ2 | `/customer/inquiry2` | Inquiry with browse (PF5/6/7/8) |
| **INQ3** | CUSTINQ3 | `/customer/inquiry3` | Inquiry with invoices |
| **MNT1** | CUSTMNT1 | `/customer/maintenance` | Add/Change/Delete |
| **MENU** | INVMENU | `/` | Application menu |

### Conversion Highlights

**VSAM to SQL:**
```cobol
EXEC CICS READ FILE('CUSTMAS') INTO(CUSTOMER-RECORD) RIDFLD(KEY) END-EXEC
```
↓↓↓
```python
customer = customer_repo.find_by_number(customer_key)
```

**File Browse to Pagination:**
```cobol
EXEC CICS STARTBR FILE('CUSTMAS') RIDFLD(KEY) END-EXEC
EXEC CICS READNEXT FILE('CUSTMAS') INTO(RECORD) END-EXEC
```
↓↓↓
```python
customer = customer_repo.get_first()  # PF5
customer = customer_repo.get_next(key)  # PF8
```

**BMS Maps to HTML:**
- 3270 green-screen styling preserved
- PF key simulation (F3, F5-F8, F12)
- Field validation maintained

---

## 📊 Architecture Comparison

### Original Mainframe Stack

```
┌─────────────────────┐
│   3270 Terminal     │ ← User interface
└──────────┬──────────┘
           │
┌──────────▼──────────┐
│   CICS Region       │ ← Transaction processing
│  ┌───────────────┐  │
│  │ COBOL Programs│  │
│  └───────┬───────┘  │
│  ┌───────▼───────┐  │
│  │  BMS Maps     │  │
│  └───────────────┘  │
└──────────┬──────────┘
           │
┌──────────▼──────────┐
│   VSAM Files        │ ← Data storage
└─────────────────────┘
```

### Modern Python Stack

```
┌─────────────────────┐
│   Web Browser       │ ← User interface
└──────────┬──────────┘
           │ HTTP/HTTPS
┌──────────▼──────────┐
│   Flask Server      │ ← Web framework
│  ┌───────────────┐  │
│  │ Python Routes │  │
│  └───────┬───────┘  │
│  ┌───────▼───────┐  │
│  │Jinja2 Templates│ │
│  └───────────────┘  │
└──────────┬──────────┘
           │
┌──────────▼──────────┐
│  SQLite Database    │ ← Data storage
└─────────────────────┘
```

---

## 🗄️ Data Model

### Customer Master (VSAM CUSTMAS → SQL customers)

| COBOL Field | COBOL Type | SQL Column | SQL Type |
|-------------|------------|------------|----------|
| CM-CUSTOMER-NUMBER | PIC 9(6) | customer_number | INTEGER PRIMARY KEY |
| CM-FIRST-NAME | PIC X(20) | first_name | VARCHAR(20) |
| CM-LAST-NAME | PIC X(30) | last_name | VARCHAR(30) |
| CM-ADDRESS | PIC X(30) | address | VARCHAR(30) |
| CM-CITY | PIC X(20) | city | VARCHAR(20) |
| CM-STATE | PIC XX | state | CHAR(2) |
| CM-ZIP-CODE | PIC X(10) | zip_code | VARCHAR(10) |

**Additional Tables:**
- `products` - Product master (VSAM PRODUCT)
- `invoices` - Invoice header (VSAM INVOICE)
- `invoice_items` - Invoice line items
- Indexes for performance (replaces VSAM alternate indexes)

---

## 🎓 Learning Resources

### For CICS Programmers

If you're a CICS programmer looking to understand modern web development:

1. **Start Here:** [Complete Conversion Guide](https://github.com/YOUR-USERNAME/kicks-to-python/blob/main/KICKS_TO_PYTHON_CONVERSION_GUIDE.md) - Full CICS to Python patterns
2. **Then Read:** [Python Application Guide](https://github.com/YOUR-USERNAME/kicks-to-python/blob/main/README.md) - Understanding the converted app
3. **Practice With:** The working application - clone and run `python app.py`

### For Python Developers

If you're a Python developer working with legacy systems:

1. **Start Here:** [Complete Conversion Guide](https://github.com/YOUR-USERNAME/kicks-to-python/blob/main/KICKS_TO_PYTHON_CONVERSION_GUIDE.md) - Understand CICS concepts
2. **Then Read:** [COBOL Source Documentation](https://github.com/YOUR-USERNAME/kicks-to-python/blob/main/cobol-source/README.md) - Original COBOL programs
3. **Study:** Compare COBOL source with Python implementation

### For Everyone

- [**Complete Conversion Guide**](https://github.com/YOUR-USERNAME/kicks-to-python/blob/main/KICKS_TO_PYTHON_CONVERSION_GUIDE.md) - 60+ page comprehensive guide
- [**Python Application README**](https://github.com/YOUR-USERNAME/kicks-to-python/blob/main/README.md) - Quick start and features
- [**COBOL Source Documentation**](https://github.com/YOUR-USERNAME/kicks-to-python/blob/main/cobol-source/README.md) - Original programs reference
- [**GitHub Upload Guide**](https://github.com/YOUR-USERNAME/kicks-to-python/blob/main/GITHUB_UPLOAD_INSTRUCTIONS.md) - How to upload to GitHub

---

## 🛠️ Technology Stack

### Python Application
- **Flask 3.0** - Web framework
- **SQLite 3** - Database
- **Jinja2** - Template engine
- **Python 3.8+** - Programming language

### Original COBOL
- **MVS 3.8J TK4** - Operating system
- **KICKS** - CICS replacement
- **COBOL (ANSI)** - Programming language
- **VSAM KSDS** - File system
- **BMS** - Screen definition

---

## 🎯 Use Cases

### Enterprise Modernization

Use this project as a reference for:
- Planning mainframe modernization projects
- Training staff on conversion techniques
- Prototyping new architectures
- Cost estimation for conversions

### Education

Perfect for:
- Teaching CICS programming concepts
- Demonstrating legacy system modernization
- Learning Python/Flask with real examples
- Understanding VSAM to SQL migration

### Development

Great starting point for:
- Your own conversion projects
- Proof-of-concept demonstrations
- Architecture evaluation
- Pattern library creation

---

## 📖 What's in the Repository

```
kicks-to-python/
├── app.py                          # Flask application
├── models.py                       # Data models
├── database.py                     # Database layer
├── templates/                      # HTML templates
│   ├── base.html
│   ├── customer_inquiry.html
│   ├── customer_inquiry2.html
│   ├── customer_inquiry3.html
│   ├── customer_maintenance.html
│   └── ...
├── cobol-source/                   # Original COBOL
│   ├── CUSTINQ1.cbl
│   ├── CUSTINQ2.cbl
│   ├── CUSTMNT1.cbl
│   ├── INVMENU.cbl
│   ├── bms-maps/
│   └── README.md
├── docs/                           # Documentation
│   ├── index.md                    # This page
│   ├── _config.yml                 # GitHub Pages config
│   └── ...
├── KICKS_TO_PYTHON_CONVERSION_GUIDE.md  # 60+ page guide
├── requirements.txt                # Python dependencies
└── README.md                       # Repository README
```

---

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### Code Contributions
- Add more program conversions (ORDRENT, CUSTINQ3, etc.)
- Improve error handling
- Add unit tests
- Enhance documentation

### Documentation
- Fix typos and clarify explanations
- Add more examples
- Translate to other languages
- Create video tutorials

### Feedback
- Report bugs via [GitHub Issues](https://github.com/YOUR-USERNAME/kicks-to-python/issues)
- Suggest improvements
- Share your conversion experiences
- Ask questions in [Discussions](https://github.com/YOUR-USERNAME/kicks-to-python/discussions)

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](https://github.com/YOUR-USERNAME/kicks-to-python/blob/main/LICENSE) file for details.

**Attribution:**
- Original COBOL programs based on examples from "CICS for the COBOL Programmer" by Doug Lowe
- Published by Mike Murach & Associates, Inc.
- KICKS by moshix - https://github.com/moshix/kicks

---

## 🙏 Acknowledgments

This project builds upon the excellent work of:

- **Doug Lowe** - Original CICS sample applications
- **Mike Murach & Associates** - Publisher of the CICS programming book
- **moshix** - Creator of KICKS for TSO/MVS
- **IBM** - CICS, COBOL, and MVS technologies

---

## 📞 Support

Need help? Here are your options:

- **📖 Documentation:** Start with this site
- **💬 Discussions:** Use GitHub Discussions for questions
- **🐛 Bug Reports:** Open a GitHub Issue
- **📧 Email:** Contact through GitHub profile

---

## 🌟 Star the Repository

If this project helps you, please give it a star on GitHub! ⭐

It helps others discover this resource for mainframe modernization.

[**⭐ Star on GitHub →**](https://github.com/YOUR-USERNAME/kicks-to-python)

---

## 🔗 Quick Links

### Documentation
- [Quick Start](#quick-start)
- [Conversion Guide](https://github.com/YOUR-USERNAME/kicks-to-python/blob/main/KICKS_TO_PYTHON_CONVERSION_GUIDE.md)
- [COBOL Reference](cobol-reference.html)
- [API Documentation](api-reference.html)

### Resources
- [GitHub Repository](https://github.com/YOUR-USERNAME/kicks-to-python)
- [Report an Issue](https://github.com/YOUR-USERNAME/kicks-to-python/issues)
- [View Source Code](https://github.com/YOUR-USERNAME/kicks-to-python)

### External Links
- [KICKS for TSO](https://github.com/moshix/kicks)
- [Murach's CICS Book](https://www.murach.com/shop/murach-s-cics-for-the-cobol-programmer-detail)
- [Flask Documentation](https://flask.palletsprojects.com/)

---

<div align="center">

**Made with ❤️ for the mainframe modernization community**

</div>
