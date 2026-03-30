# KICKS/COBOL to Python Conversion
### Modernizing Legacy Mainframe Applications

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![Flask](https://img.shields.io/badge/flask-3.0+-green.svg)](https://flask.palletsprojects.com/)

> **A complete, working example of converting CICS/COBOL applications to modern Python web applications**

This repository demonstrates the full conversion of Doug Lowe's classic CICS sample application suite from KICKS/COBOL running on MVS 3.8J to a modern Python Flask web application with SQLite database.

📚 **[View Documentation Site](https://tsiitz.github.io/kicks-to-python/)** 

---

## 🎯 What's This Project?

This is a **complete, runnable conversion** showing how to modernize legacy mainframe applications:

- **Original:** CICS/COBOL programs + BMS maps + VSAM files (MVS 3.8J)
- **Converted:** Python/Flask web app + HTML templates + SQLite database
- **Plus:** Original COBOL source code for comparison

![Customer Inquiry Screenshot](docs/images/screenshot-inq1.png)

### Why This Matters

Thousands of enterprises still run critical business applications on mainframes with CICS/COBOL. This project provides:

✅ Real working code (not just theory)  
✅ Complete conversion patterns  
✅ Both original COBOL and converted Python  
✅ Side-by-side comparison of architectures  
✅ Production-ready starting point

---

## 🚀 Quick Start

### Run the Python Application

```bash
# Clone the repository
git clone https://github.com/tsiitz/kicks-to-python.git
cd kicks-to-python

# Install dependencies
pip install -r requirements.txt

# Run the application
python app.py

# Open browser to http://localhost:5000
```

**That's it!** The application automatically:
- Creates the SQLite database
- Loads sample data (7 customers, 5 products, 4 invoices)
- Starts the Flask web server

**Sample Data:**
- Customer Numbers: 400001, 400002, 400003, 400004, 400005, 400006, 400007
- Product Codes: 0000000001, 0000000005, 0000000010, 0000000020, 0000000025

---

## 📦 What's Included

### Python Web Application

| File | Description |
|------|-------------|
| `app.py` | Flask web application with all routes (CICS transactions) |
| `models.py` | Data models - COBOL records → Python dataclasses |
| `database.py` | Database layer - VSAM operations → SQL queries |
| `templates/` | HTML templates - BMS maps → Jinja2 with 3270 styling |
| `requirements.txt` | Python dependencies |

**Converted Transactions:**
- **INQ1** - Customer inquiry
- **INQ2** - Customer inquiry with browse (PF5/6/7/8)
- **INQ3** - Customer inquiry with invoices  
- **MNT1** - Customer maintenance (Add/Change/Delete)
- **MENU** - Application menu
- **LIST** - Customer list report

### COBOL Source Code (`/cobol-source/`)

| Program | Lines | Description |
|---------|-------|-------------|
| `CUSTINQ1.cbl` | 170 | Basic customer inquiry |
| `CUSTINQ2.cbl` | 380 | Customer inquiry with file browse |
| `CUSTMNT1.cbl` | 430 | Customer maintenance |
| `INVMENU.cbl` | 120 | Application menu |

Plus BMS map definitions and comprehensive documentation.

### Documentation

- **[KICKS_TO_PYTHON_CONVERSION_GUIDE.md](KICKS_TO_PYTHON_CONVERSION_GUIDE.md)** - 60+ page comprehensive guide
- **[cobol-source/README.md](cobol-source/README.md)** - COBOL program documentation
- **[docs/](docs/)** - GitHub Pages documentation site

---

## 🔑 Key Conversion Patterns

### VSAM File → SQL Table

**COBOL:**
```cobol
EXEC CICS READ FILE('CUSTMAS')
     INTO(CUSTOMER-MASTER-RECORD)
     RIDFLD(CM-CUSTOMER-NUMBER)
END-EXEC
```

**Python:**
```python
customer = customer_repo.find_by_number(customer_number)
```

### File Browse → SQL Pagination

**COBOL:**
```cobol
EXEC CICS STARTBR FILE('CUSTMAS') RIDFLD(KEY) GTEQ END-EXEC
EXEC CICS READNEXT FILE('CUSTMAS') INTO(RECORD) END-EXEC
```

**Python:**
```python
customer = customer_repo.get_first()  # PF5
customer = customer_repo.get_next(current_number)  # PF8
```

### Pseudo-Conversational → Flask Sessions

**COBOL:**
```cobol
EXEC CICS RETURN TRANSID('INQ1') COMMAREA(COMMUNICATION-AREA) END-EXEC
```

**Python:**
```python
session['mnt_customer_number'] = customer_number
return redirect(url_for('customer_detail'))
```

---

## 🎨 Features

- ✅ Authentic 3270 terminal styling (green-on-black)
- ✅ PF key simulation (F3, F5-F8, F12)
- ✅ Complete database layer with repository pattern
- ✅ VSAM browse operations → SQL pagination
- ✅ Pseudo-conversational design → Flask sessions
- ✅ BMS maps → HTML templates with Jinja2
- ✅ Error handling and validation
- ✅ Sample data included

---

## 🗄️ Database Schema

### customers (VSAM CUSTMAS)

| Column | Type | Description |
|--------|------|-------------|
| customer_number | INTEGER PRIMARY KEY | 6-digit customer number |
| first_name | VARCHAR(20) | Customer first name |
| last_name | VARCHAR(30) | Customer last name |
| address | VARCHAR(30) | Street address |
| city | VARCHAR(20) | City |
| state | CHAR(2) | State code |
| zip_code | VARCHAR(10) | ZIP code |

### products, invoices, invoice_items
Complete schema for all VSAM files converted to SQL tables.

---

## 🛠️ Technology Stack

**Python Application:**
- Flask 3.0 - Web framework
- SQLite 3 - Database
- Jinja2 - Templates
- Python 3.8+

**Original COBOL:**
- MVS 3.8J TK4 - Operating system
- KICKS - CICS replacement
- COBOL (ANSI) - Programming language
- VSAM KSDS - File system

---

## 📚 Documentation

This repository includes extensive documentation:

1. **[README.md](README.md)** - This file - Quick start and overview
2. **[KICKS_TO_PYTHON_CONVERSION_GUIDE.md](KICKS_TO_PYTHON_CONVERSION_GUIDE.md)** - Comprehensive 60+ page conversion guide
3. **[cobol-source/README.md](cobol-source/README.md)** - COBOL program documentation
4. **[GitHub Pages Site](https://tsiitz.github.io/kicks-to-python/)** - Beautiful documentation website

### What's in the Conversion Guide

- Application overview and architecture decisions
- Data migration strategies (VSAM → SQL)
- Program conversion patterns (COBOL → Python)
- BMS map conversion (3270 → HTML)
- Implementation roadmap (16-week plan)
- Complete code examples for every pattern

---

## 🎯 Use Cases

### Learning
- Study authentic CICS programming patterns
- Understand mainframe → web conversion
- Learn Flask/Python with real-world example
- See VSAM → SQL migration in action

### Reference
- Template for your own conversion projects
- Copy proven conversion patterns
- Model architecture after this example

### Teaching
- Mainframe programming courses
- Web development with legacy integration
- Database migration techniques

---

## 📸 Screenshots

### Customer Inquiry (INQ1)
![Customer Inquiry](docs/images/screenshot-inq1.png)

### Customer List
![Customer List](docs/images/screenshot-list.png)

### Customer Maintenance
![Customer Maintenance](docs/images/screenshot-mnt1.png)

---

## 🤝 Contributing

Contributions welcome! Please feel free to:

- Report bugs via GitHub issues
- Submit pull requests with enhancements
- Improve documentation
- Add more program conversions

---

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details.

**Attribution:**
- Original COBOL programs based on examples from "CICS for the COBOL Programmer" by Doug Lowe (Murach & Associates)
- KICKS by moshix - https://github.com/moshix/kicks

---

## 🙏 Credits

- **Doug Lowe** - Original CICS sample applications
- **Mike Murach & Associates** - Publisher of "CICS for the COBOL Programmer"
- **moshix** - KICKS for TSO/MVS
- **IBM** - CICS, COBOL, MVS technologies

---

## 🌟 Star This Repo

If you find this project useful, please give it a star! ⭐

It helps others discover this resource for mainframe modernization.

---

<div align="center">

**Made with ❤️ for the mainframe modernization community**

[View Documentation](https://tsiitz.github.io/kicks-to-python/) • [Report Bug](https://github.com/tsiitz/kicks-to-python/issues) • [Request Feature](https://github.com/tsiitz/kicks-to-python/issues)

</div>
