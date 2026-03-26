# KICKS/COBOL to Python Conversion Guide
## Doug Lowe's CICS Sample Application Suite

---

## Table of Contents
1. [Application Overview](#application-overview)
2. [Architecture Decision](#architecture-decision)
3. [Data Migration Strategy](#data-migration-strategy)
4. [Program Conversion Patterns](#program-conversion-patterns)
5. [BMS Map Conversion](#bms-map-conversion)
6. [Implementation Roadmap](#implementation-roadmap)
7. [Code Examples](#code-examples)

---

## Application Overview

### Source System: KICKS on MVS 3.8J TK4
The application consists of:

#### **VSAM Files (4 files + 1 alternate index)**
```
CUSTMAS  - Customer Master (KSDS, key: CUSTOMER-NUMBER, 6 digits)
INVCTL   - Inventory Control (KSDS)
PRODUCT  - Product Master (KSDS, key: PRODUCT-CODE, 10 digits)
INVOICE  - Invoice records (KSDS, key: INVOICE-NUMBER, 6 digits)
INVPATH  - Alternate index on INVOICE (by CUSTOMER-NUMBER)
```

#### **Programs (15 main transactions)**
| Transaction | Program    | Function                          | Complexity |
|-------------|------------|-----------------------------------|------------|
| INQ1        | CUSTINQ1   | Basic customer inquiry            | Simple     |
| INQ2        | CUSTINQ2   | Customer inquiry with browse      | Medium     |
| INQ3        | CUSTINQ3   | Customer inquiry + invoices       | Complex    |
| MNT1        | CUSTMNT1   | Customer maintenance (basic)      | Medium     |
| MNT2        | CUSTMNT2   | Customer maintenance (enhanced)   | Medium     |
| MNT3        | CUSTMNT3   | Customer maintenance (advanced)   | Complex    |
| CMNT        | CMNTP/B    | Structured maintenance            | Complex    |
| MENU        | INVMENU    | Application menu                  | Simple     |
| ORD1        | ORDRENT    | Order entry system                | Complex    |
| SUM1        | INVSUM1    | Invoice summary report            | Medium     |
| DFXX        | DFXXP00A   | Debug/abend demonstration         | Simple     |
|             | GETINV     | Linked routine (get inventory)    | Simple     |
|             | SYSERR     | Error handler (linked)            | Simple     |
|             | INTEDIT    | Integer validation (called)       | Simple     |
|             | NUMEDIT    | Numeric validation (called)       | Simple     |

#### **BMS Maps (10 mapsets)**
```
INQSET1  - Customer inquiry map (INQ1)
INQSET2  - Customer inquiry map (INQ2)
INQSET3  - Customer inquiry + invoices (INQ3)
MNTSET1  - Customer maintenance map (MNT1)
MNTSET2  - Customer maintenance map (MNT2)
MENSET1  - Menu screen
ORDSET1  - Order entry screen
SUMSET1  - Summary report screen
DB2SET1  - DB2 inquiry map (DIN1)
CMNTSET  - Structured maintenance map
```

---

## Architecture Decision

### Option A: Terminal-Based (Closest to Original)
**Pros:**
- Most faithful to original user experience
- Uses Python `textual` or `curses` for 3270-like interface
- Easier conversion of screen logic
- No web server complexity

**Cons:**
- Limited to terminal users
- Not suitable for modern deployment
- Harder to integrate with other systems

### Option B: Web-Based (Recommended)
**Pros:**
- Modern, accessible interface
- Easy to deploy and scale
- Can add features (search, filtering, reports)
- Mobile-friendly potential
- RESTful API for integrations

**Cons:**
- More initial work
- Requires translating 3270 concepts to HTML
- Session management needed

### Option C: Hybrid Approach
**Best of both worlds:**
1. Python backend with SQLite/PostgreSQL
2. REST API layer
3. Multiple frontends:
   - Web UI (Flask/FastAPI + HTML/Tailwind)
   - Terminal UI (textual) for power users
   - API for automation

---

## Data Migration Strategy

### Phase 1: Extract VSAM Data

The XMI file needs to be restored on MVS 3.8J first to get the actual data files. However, for development, you can create sample data directly.

#### Customer Master Record Layout (from COBOL copybook)
```cobol
01  CUSTOMER-MASTER-RECORD.
    05  CM-CUSTOMER-NUMBER      PIC 9(6).
    05  CM-FIRST-NAME           PIC X(20).
    05  CM-LAST-NAME            PIC X(30).
    05  CM-ADDRESS              PIC X(30).
    05  CM-CITY                 PIC X(20).
    05  CM-STATE                PIC XX.
    05  CM-ZIP-CODE             PIC X(10).
```

#### Convert to SQL Schema
```sql
-- Customer Master Table
CREATE TABLE customers (
    customer_number INTEGER PRIMARY KEY,
    first_name VARCHAR(20) NOT NULL,
    last_name VARCHAR(30) NOT NULL,
    address VARCHAR(30),
    city VARCHAR(20),
    state CHAR(2),
    zip_code VARCHAR(10),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Product Master Table
CREATE TABLE products (
    product_code VARCHAR(10) PRIMARY KEY,
    product_description VARCHAR(40),
    unit_price DECIMAL(7,2),
    quantity_on_hand INTEGER,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Invoice Header Table
CREATE TABLE invoices (
    invoice_number INTEGER PRIMARY KEY,
    customer_number INTEGER NOT NULL,
    invoice_date DATE,
    invoice_total DECIMAL(9,2),
    FOREIGN KEY (customer_number) REFERENCES customers(customer_number)
);

-- Invoice Line Items
CREATE TABLE invoice_items (
    invoice_number INTEGER,
    line_number INTEGER,
    product_code VARCHAR(10),
    quantity INTEGER,
    line_total DECIMAL(9,2),
    PRIMARY KEY (invoice_number, line_number),
    FOREIGN KEY (invoice_number) REFERENCES invoices(invoice_number),
    FOREIGN KEY (product_code) REFERENCES products(product_code)
);

-- Indexes for performance (replaces alternate indexes)
CREATE INDEX idx_invoice_customer ON invoices(customer_number);
CREATE INDEX idx_invoice_date ON invoices(invoice_date);
```

### Phase 2: Data Type Conversions

#### COBOL → Python Type Mapping
```python
from dataclasses import dataclass
from decimal import Decimal
from datetime import date, datetime
from typing import Optional

# COBOL PIC 9(6) → Python int
# COBOL PIC X(30) → Python str
# COBOL PIC S9(7)V99 COMP-3 → Python Decimal

@dataclass
class Customer:
    """Represents CUSTOMER-MASTER-RECORD"""
    customer_number: int              # PIC 9(6)
    first_name: str                   # PIC X(20)
    last_name: str                    # PIC X(30)
    address: str                      # PIC X(30)
    city: str                         # PIC X(20)
    state: str                        # PIC XX
    zip_code: str                     # PIC X(10)
    created_date: Optional[datetime] = None
    modified_date: Optional[datetime] = None
    
    def to_dict(self):
        """Convert to dictionary for JSON/database"""
        return {
            'customer_number': self.customer_number,
            'first_name': self.first_name.strip(),
            'last_name': self.last_name.strip(),
            'address': self.address.strip(),
            'city': self.city.strip(),
            'state': self.state,
            'zip_code': self.zip_code.strip()
        }

@dataclass
class Product:
    """Represents PRODUCT-MASTER-RECORD"""
    product_code: str                 # PIC X(10)
    description: str                  # PIC X(40)
    unit_price: Decimal              # PIC S9(5)V99 COMP-3
    quantity_on_hand: int            # PIC S9(7) COMP-3
```

### Phase 3: Migration Scripts

```python
# vsam_migration.py
import sqlite3
from decimal import Decimal
from typing import List
import csv

class VSAMMigrator:
    """Migrates VSAM files to SQL database"""
    
    def __init__(self, db_path: str = 'mainframe.db'):
        self.conn = sqlite3.connect(db_path)
        self.cursor = self.conn.cursor()
        self.create_tables()
    
    def create_tables(self):
        """Create all SQL tables"""
        # Execute all CREATE TABLE statements from above
        with open('schema.sql', 'r') as f:
            self.conn.executescript(f.read())
    
    def import_customers(self, csv_file: str):
        """Import customer data from CSV export"""
        with open(csv_file, 'r') as f:
            reader = csv.DictReader(f)
            for row in reader:
                self.cursor.execute('''
                    INSERT INTO customers 
                    (customer_number, first_name, last_name, address, city, state, zip_code)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                ''', (
                    int(row['customer_number']),
                    row['first_name'].strip(),
                    row['last_name'].strip(),
                    row['address'].strip(),
                    row['city'].strip(),
                    row['state'],
                    row['zip_code'].strip()
                ))
        self.conn.commit()
    
    def import_products(self, csv_file: str):
        """Import product data from CSV export"""
        with open(csv_file, 'r') as f:
            reader = csv.DictReader(f)
            for row in reader:
                self.cursor.execute('''
                    INSERT INTO products
                    (product_code, product_description, unit_price, quantity_on_hand)
                    VALUES (?, ?, ?, ?)
                ''', (
                    row['product_code'],
                    row['description'],
                    Decimal(row['unit_price']),
                    int(row['quantity_on_hand'])
                ))
        self.conn.commit()

# Sample data generation (for testing)
def create_sample_data():
    """Create sample test data matching Murach examples"""
    migrator = VSAMMigrator()
    
    # Sample customers (from book examples)
    customers = [
        (400001, 'Keith', 'Jones', '5841 Oak Leaf Drive', 'Campbell', 'CA', '95008'),
        (400002, 'Lisa', 'Smith', '3812 Oak Leaf Drive', 'Campbell', 'CA', '95008'),
        (400003, 'Susan', 'Myers', '4819 Willow Way', 'San Jose', 'CA', '95110'),
        (400004, 'John', 'Davis', '9201 Pine Street', 'Sunnyvale', 'CA', '94086'),
        (400005, 'Anne', 'Wright', '1432 Elm Avenue', 'San Jose', 'CA', '95112'),
    ]
    
    for cust in customers:
        migrator.cursor.execute('''
            INSERT INTO customers 
            (customer_number, first_name, last_name, address, city, state, zip_code)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ''', cust)
    
    # Sample products
    products = [
        ('0000000001', 'Widget Standard', Decimal('10.50'), 500),
        ('0000000005', 'Gadget Deluxe', Decimal('25.99'), 250),
        ('0000000010', 'Doohickey Pro', Decimal('99.99'), 100),
    ]
    
    for prod in products:
        migrator.cursor.execute('''
            INSERT INTO products
            (product_code, product_description, unit_price, quantity_on_hand)
            VALUES (?, ?, ?, ?)
        ''', prod)
    
    migrator.conn.commit()
    print("Sample data created successfully!")

if __name__ == '__main__':
    create_sample_data()
```

---

## Program Conversion Patterns

### CICS/KICKS API → Python Equivalents

#### Common CICS Commands
```cobol
EXEC CICS RECEIVE MAP('INQMAP1') MAPSET('INQSET1') END-EXEC
EXEC CICS READ FILE('CUSTMAS') INTO(CUSTOMER-RECORD) 
          RIDFLD(CUSTOMER-KEY) END-EXEC
EXEC CICS SEND MAP('INQMAP1') MAPSET('INQSET1') END-EXEC
EXEC CICS RETURN TRANSID('INQ1') END-EXEC
```

#### Python Web Equivalent
```python
from flask import Flask, request, render_template, session
import sqlite3

app = Flask(__name__)
app.secret_key = 'your-secret-key'

@app.route('/customer/inquiry', methods=['GET', 'POST'])
def customer_inquiry():
    """Equivalent to CUSTINQ1 program"""
    
    if request.method == 'POST':
        # RECEIVE MAP equivalent
        customer_number = request.form.get('customer_number')
        
        # READ FILE equivalent
        conn = sqlite3.connect('mainframe.db')
        cursor = conn.cursor()
        cursor.execute(
            'SELECT * FROM customers WHERE customer_number = ?',
            (customer_number,)
        )
        customer = cursor.fetchone()
        conn.close()
        
        if customer:
            # SEND MAP equivalent with data
            return render_template('customer_inquiry.html',
                                 customer_number=customer[0],
                                 first_name=customer[1],
                                 last_name=customer[2],
                                 address=customer[3],
                                 city=customer[4],
                                 state=customer[5],
                                 zip_code=customer[6],
                                 message='Customer found')
        else:
            # NOTFND condition
            return render_template('customer_inquiry.html',
                                 customer_number=customer_number,
                                 error='Customer not found')
    
    # Initial screen display
    return render_template('customer_inquiry.html')
```

### COBOL Program Structure → Python Class

#### Original COBOL (CUSTINQ1)
```cobol
IDENTIFICATION DIVISION.
PROGRAM-ID. CUSTINQ1.

WORKING-STORAGE SECTION.
01  CUSTOMER-MASTER-RECORD.
    05  CM-CUSTOMER-NUMBER      PIC 9(6).
    05  CM-FIRST-NAME           PIC X(20).
    05  CM-LAST-NAME            PIC X(30).

PROCEDURE DIVISION.
0000-PROCESS-CUSTOMER-INQUIRY.
    EXEC CICS RECEIVE MAP('INQMAP1') MAPSET('INQSET1') END-EXEC.
    MOVE CUSTNO-I TO CM-CUSTOMER-NUMBER.
    EXEC CICS READ FILE('CUSTMAS') INTO(CUSTOMER-MASTER-RECORD)
              RIDFLD(CM-CUSTOMER-NUMBER) END-EXEC.
    MOVE CM-FIRST-NAME TO FNAME-O.
    EXEC CICS SEND MAP('INQMAP1') MAPSET('INQSET1') END-EXEC.
    EXEC CICS RETURN END-EXEC.
```

#### Converted Python Class
```python
# customer_inquiry.py
from dataclasses import dataclass
from typing import Optional
import sqlite3

@dataclass
class CustomerInquiryInput:
    """Represents input from INQMAP1"""
    customer_number: int

@dataclass
class CustomerInquiryOutput:
    """Represents output to INQMAP1"""
    customer_number: int
    first_name: str
    last_name: str
    address: str
    city: str
    state: str
    zip_code: str
    message: str = ""
    error: str = ""

class CustomerInquiryService:
    """Business logic for CUSTINQ1"""
    
    def __init__(self, db_path: str = 'mainframe.db'):
        self.db_path = db_path
    
    def process_inquiry(self, input_data: CustomerInquiryInput) -> CustomerInquiryOutput:
        """Main processing logic - equivalent to 0000-PROCESS-CUSTOMER-INQUIRY"""
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        try:
            # READ FILE('CUSTMAS')
            cursor.execute('''
                SELECT customer_number, first_name, last_name, 
                       address, city, state, zip_code
                FROM customers
                WHERE customer_number = ?
            ''', (input_data.customer_number,))
            
            row = cursor.fetchone()
            
            if row:
                # Customer found - populate output
                return CustomerInquiryOutput(
                    customer_number=row[0],
                    first_name=row[1],
                    last_name=row[2],
                    address=row[3],
                    city=row[4],
                    state=row[5],
                    zip_code=row[6],
                    message="Customer record displayed"
                )
            else:
                # NOTFND condition
                return CustomerInquiryOutput(
                    customer_number=input_data.customer_number,
                    first_name="",
                    last_name="",
                    address="",
                    city="",
                    state="",
                    zip_code="",
                    error="Customer not found"
                )
                
        finally:
            conn.close()
```

---

## BMS Map Conversion

### Original BMS Map Definition
```
INQSET1  DFHMSD TYPE=&SYSPARM,LANG=COBOL,MODE=INOUT,TERM=3270-2,      X
               CTRL=FREEKB,STORAGE=AUTO,TIOAPFX=YES
INQMAP1  DFHMDI SIZE=(24,80),LINE=1,COLUMN=1
         DFHMDF POS=(1,1),LENGTH=7,ATTRB=(NORM,PROT),                 X
               INITIAL='INQ1'
         DFHMDF POS=(1,20),LENGTH=35,ATTRB=(NORM,PROT),               X
               INITIAL='CUSTOMER INQUIRY'
         DFHMDF POS=(3,1),LENGTH=15,ATTRB=(NORM,PROT),                X
               INITIAL='CUSTOMER NUMBER'
CUSTNO   DFHMDF POS=(3,17),LENGTH=6,ATTRB=(NORM,UNPROT,IC)
         DFHMDF POS=(3,24),LENGTH=1,ATTRB=ASKIP
         DFHMDF POS=(5,1),LENGTH=10,ATTRB=(NORM,PROT),                X
               INITIAL='FIRST NAME'
FNAME    DFHMDF POS=(5,17),LENGTH=20,ATTRB=(NORM,PROT)
         DFHMDF POS=(7,1),LENGTH=9,ATTRB=(NORM,PROT),                 X
               INITIAL='LAST NAME'
LNAME    DFHMDF POS=(7,17),LENGTH=30,ATTRB=(NORM,PROT)
```

### Converted HTML Template (Flask/Jinja2)
```html
<!-- templates/customer_inquiry.html -->
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>INQ1 - Customer Inquiry</title>
    <style>
        body {
            font-family: 'Courier New', monospace;
            background-color: #000;
            color: #0f0;
            padding: 20px;
            max-width: 800px;
            margin: 0 auto;
        }
        .screen-header {
            border-bottom: 1px solid #0f0;
            padding-bottom: 10px;
            margin-bottom: 20px;
        }
        .field-group {
            margin-bottom: 15px;
        }
        label {
            display: inline-block;
            width: 150px;
            color: #00ff00;
        }
        input[type="text"], input[type="number"] {
            background-color: #000;
            color: #0f0;
            border: 1px solid #0f0;
            padding: 5px;
            font-family: 'Courier New', monospace;
        }
        input[readonly] {
            border: none;
            background: transparent;
        }
        .button-group {
            margin-top: 20px;
        }
        button {
            background-color: #0f0;
            color: #000;
            border: none;
            padding: 10px 20px;
            margin-right: 10px;
            cursor: pointer;
            font-family: 'Courier New', monospace;
        }
        button:hover {
            background-color: #00cc00;
        }
        .error {
            color: #ff0000;
            font-weight: bold;
        }
        .message {
            color: #00ffff;
        }
    </style>
</head>
<body>
    <div class="screen-header">
        <span>INQ1</span>
        <span style="margin-left: 50px;">CUSTOMER INQUIRY</span>
    </div>
    
    <form method="POST" action="{{ url_for('customer_inquiry') }}">
        <div class="field-group">
            <label for="customer_number">CUSTOMER NUMBER:</label>
            <input type="number" 
                   id="customer_number" 
                   name="customer_number" 
                   maxlength="6"
                   value="{{ customer_number or '' }}"
                   autofocus>
        </div>
        
        {% if customer_number %}
        <div class="field-group">
            <label>FIRST NAME:</label>
            <input type="text" 
                   value="{{ first_name or '' }}" 
                   readonly>
        </div>
        
        <div class="field-group">
            <label>LAST NAME:</label>
            <input type="text" 
                   value="{{ last_name or '' }}" 
                   readonly>
        </div>
        
        <div class="field-group">
            <label>ADDRESS:</label>
            <input type="text" 
                   value="{{ address or '' }}" 
                   readonly>
        </div>
        
        <div class="field-group">
            <label>CITY:</label>
            <input type="text" 
                   value="{{ city or '' }}" 
                   readonly>
        </div>
        
        <div class="field-group">
            <label>STATE:</label>
            <input type="text" 
                   value="{{ state or '' }}" 
                   readonly 
                   size="2">
        </div>
        
        <div class="field-group">
            <label>ZIP CODE:</label>
            <input type="text" 
                   value="{{ zip_code or '' }}" 
                   readonly>
        </div>
        {% endif %}
        
        {% if error %}
        <div class="error">{{ error }}</div>
        {% endif %}
        
        {% if message %}
        <div class="message">{{ message }}</div>
        {% endif %}
        
        <div class="button-group">
            <button type="submit">ENTER</button>
            <button type="button" onclick="window.location.href='{{ url_for('menu') }}'">PF3-EXIT</button>
        </div>
    </form>
</body>
</html>
```

### Alternative: Terminal UI (using textual)
```python
# terminal_inquiry.py
from textual.app import App, ComposeResult
from textual.widgets import Header, Footer, Input, Static, Button
from textual.containers import Container, Horizontal
from customer_inquiry import CustomerInquiryService, CustomerInquiryInput

class CustomerInquiryApp(App):
    """Terminal-based customer inquiry (3270-style)"""
    
    CSS = """
    Screen {
        background: black;
    }
    .label {
        color: green;
        width: 20;
    }
    Input {
        background: black;
        color: green;
        border: tall green;
    }
    .readonly {
        border: none;
    }
    .error {
        color: red;
    }
    """
    
    BINDINGS = [
        ("f3", "exit", "Exit"),
        ("enter", "submit", "Submit"),
    ]
    
    def compose(self) -> ComposeResult:
        yield Header(show_clock=False)
        yield Static("INQ1 - CUSTOMER INQUIRY", classes="title")
        
        with Container():
            with Horizontal():
                yield Static("Customer Number:", classes="label")
                yield Input(placeholder="Enter 6-digit customer number", 
                          id="customer_number",
                          max_length=6)
            
            with Horizontal(id="output_fields"):
                yield Static("First Name:", classes="label")
                yield Input(id="first_name", classes="readonly", disabled=True)
            
            # Add other fields...
            
            yield Static(id="message")
            
        yield Footer()
    
    def action_submit(self):
        """Handle ENTER key"""
        customer_number_input = self.query_one("#customer_number", Input)
        customer_number = customer_number_input.value
        
        if not customer_number:
            self.query_one("#message", Static).update("[error]Enter customer number[/]")
            return
        
        service = CustomerInquiryService()
        result = service.process_inquiry(
            CustomerInquiryInput(customer_number=int(customer_number))
        )
        
        # Update output fields
        if result.error:
            self.query_one("#message", Static).update(f"[error]{result.error}[/]")
        else:
            self.query_one("#first_name", Input).value = result.first_name
            # Update other fields...
            self.query_one("#message", Static).update(f"[green]{result.message}[/]")
    
    def action_exit(self):
        """Handle PF3 key"""
        self.exit()

if __name__ == "__main__":
    app = CustomerInquiryApp()
    app.run()
```

---

## Implementation Roadmap

### Phase 1: Foundation (Week 1-2)
- [ ] Set up Python project structure
- [ ] Create SQL database schema
- [ ] Generate sample data (matching Murach examples)
- [ ] Build core data access layer
- [ ] Create base Customer, Product, Invoice classes

### Phase 2: Simple Programs First (Week 3-4)
Start with the easiest programs to build momentum:

1. **CUSTINQ1 (INQ1)** - Basic inquiry
   - Single record lookup
   - No complex logic
   - Good first program

2. **INVMENU (MENU)** - Menu program
   - Navigation only
   - Tests routing between programs

3. **DFXXP00A (DFXX)** - Debug program
   - Simple, self-contained
   - Tests error handling

### Phase 3: Medium Complexity (Week 5-7)

4. **CUSTINQ2 (INQ2)** - Inquiry with browse
   - Implements STARTBR/READNEXT pattern
   - Pagination logic

5. **CUSTMNT1 (MNT1)** - Basic maintenance
   - Add/Change/Delete operations
   - Form validation

6. **INVSUM1 (SUM1)** - Summary report
   - File scanning
   - Accumulation logic

### Phase 4: Complex Programs (Week 8-12)

7. **CUSTINQ3 (INQ3)** - Inquiry with related records
   - Master-detail relationship
   - Multiple file access

8. **CUSTMNT2 (MNT2)** - Enhanced maintenance
   - Field-level validation
   - Highlighting errors

9. **ORDRENT (ORD1)** - Order entry
   - Multi-screen pseudo-conversational
   - Complex business logic
   - Multiple file updates

10. **CMNTP/CMNTB (CMNT)** - Structured maintenance
    - Front-end/back-end pattern
    - Program-to-program communication

### Phase 5: Utilities (Week 13)

11. **GETINV** - Linked routine
12. **SYSERR** - Error handler
13. **INTEDIT/NUMEDIT** - Validation routines

### Phase 6: Testing & Refinement (Week 14-16)
- [ ] End-to-end testing
- [ ] Performance tuning
- [ ] Documentation
- [ ] Deployment preparation

---

## Code Examples

### Complete Working Example: Customer Inquiry System

#### File: `models.py`
```python
from dataclasses import dataclass
from typing import Optional
from datetime import datetime

@dataclass
class Customer:
    customer_number: int
    first_name: str
    last_name: str
    address: str
    city: str
    state: str
    zip_code: str
    created_date: Optional[datetime] = None
    modified_date: Optional[datetime] = None
```

#### File: `database.py`
```python
import sqlite3
from typing import Optional, List
from contextlib import contextmanager
from models import Customer

class Database:
    def __init__(self, db_path: str = 'mainframe.db'):
        self.db_path = db_path
        self.init_database()
    
    @contextmanager
    def get_connection(self):
        """Context manager for database connections"""
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        try:
            yield conn
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:
            conn.close()
    
    def init_database(self):
        """Initialize database schema"""
        with self.get_connection() as conn:
            conn.execute('''
                CREATE TABLE IF NOT EXISTS customers (
                    customer_number INTEGER PRIMARY KEY,
                    first_name VARCHAR(20) NOT NULL,
                    last_name VARCHAR(30) NOT NULL,
                    address VARCHAR(30),
                    city VARCHAR(20),
                    state CHAR(2),
                    zip_code VARCHAR(10),
                    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            ''')

class CustomerRepository:
    """Data access for Customer records - replaces VSAM CUSTMAS file"""
    
    def __init__(self, database: Database):
        self.db = database
    
    def find_by_number(self, customer_number: int) -> Optional[Customer]:
        """READ FILE('CUSTMAS') RIDFLD(CUSTOMER-NUMBER)"""
        with self.db.get_connection() as conn:
            cursor = conn.execute(
                '''SELECT customer_number, first_name, last_name, 
                          address, city, state, zip_code
                   FROM customers 
                   WHERE customer_number = ?''',
                (customer_number,)
            )
            row = cursor.fetchone()
            
            if row:
                return Customer(
                    customer_number=row['customer_number'],
                    first_name=row['first_name'],
                    last_name=row['last_name'],
                    address=row['address'],
                    city=row['city'],
                    state=row['state'],
                    zip_code=row['zip_code']
                )
            return None
    
    def get_first(self) -> Optional[Customer]:
        """STARTBR + READNEXT (first record)"""
        with self.db.get_connection() as conn:
            cursor = conn.execute(
                '''SELECT customer_number, first_name, last_name,
                          address, city, state, zip_code
                   FROM customers 
                   ORDER BY customer_number ASC 
                   LIMIT 1'''
            )
            row = cursor.fetchone()
            return self._row_to_customer(row) if row else None
    
    def get_last(self) -> Optional[Customer]:
        """STARTBR + READPREV (last record)"""
        with self.db.get_connection() as conn:
            cursor = conn.execute(
                '''SELECT customer_number, first_name, last_name,
                          address, city, state, zip_code
                   FROM customers 
                   ORDER BY customer_number DESC 
                   LIMIT 1'''
            )
            row = cursor.fetchone()
            return self._row_to_customer(row) if row else None
    
    def get_next(self, customer_number: int) -> Optional[Customer]:
        """READNEXT after current position"""
        with self.db.get_connection() as conn:
            cursor = conn.execute(
                '''SELECT customer_number, first_name, last_name,
                          address, city, state, zip_code
                   FROM customers 
                   WHERE customer_number > ? 
                   ORDER BY customer_number ASC 
                   LIMIT 1''',
                (customer_number,)
            )
            row = cursor.fetchone()
            return self._row_to_customer(row) if row else None
    
    def get_previous(self, customer_number: int) -> Optional[Customer]:
        """READPREV before current position"""
        with self.db.get_connection() as conn:
            cursor = conn.execute(
                '''SELECT customer_number, first_name, last_name,
                          address, city, state, zip_code
                   FROM customers 
                   WHERE customer_number < ? 
                   ORDER BY customer_number DESC 
                   LIMIT 1''',
                (customer_number,)
            )
            row = cursor.fetchone()
            return self._row_to_customer(row) if row else None
    
    def create(self, customer: Customer) -> Customer:
        """WRITE FILE('CUSTMAS')"""
        with self.db.get_connection() as conn:
            conn.execute(
                '''INSERT INTO customers 
                   (customer_number, first_name, last_name, address, 
                    city, state, zip_code)
                   VALUES (?, ?, ?, ?, ?, ?, ?)''',
                (customer.customer_number, customer.first_name,
                 customer.last_name, customer.address, customer.city,
                 customer.state, customer.zip_code)
            )
        return customer
    
    def update(self, customer: Customer) -> Customer:
        """REWRITE FILE('CUSTMAS')"""
        with self.db.get_connection() as conn:
            conn.execute(
                '''UPDATE customers 
                   SET first_name = ?, last_name = ?, address = ?,
                       city = ?, state = ?, zip_code = ?,
                       modified_date = CURRENT_TIMESTAMP
                   WHERE customer_number = ?''',
                (customer.first_name, customer.last_name, customer.address,
                 customer.city, customer.state, customer.zip_code,
                 customer.customer_number)
            )
        return customer
    
    def delete(self, customer_number: int) -> bool:
        """DELETE FILE('CUSTMAS')"""
        with self.db.get_connection() as conn:
            cursor = conn.execute(
                'DELETE FROM customers WHERE customer_number = ?',
                (customer_number,)
            )
            return cursor.rowcount > 0
    
    def _row_to_customer(self, row) -> Customer:
        """Convert database row to Customer object"""
        return Customer(
            customer_number=row['customer_number'],
            first_name=row['first_name'],
            last_name=row['last_name'],
            address=row['address'],
            city=row['city'],
            state=row['state'],
            zip_code=row['zip_code']
        )
```

#### File: `app.py` (Flask Web Application)
```python
from flask import Flask, render_template, request, redirect, url_for, session
from database import Database, CustomerRepository
from models import Customer

app = Flask(__name__)
app.secret_key = 'your-secret-key-here'

# Initialize database
db = Database()
customer_repo = CustomerRepository(db)

@app.route('/')
def index():
    """Main menu - INVMENU equivalent"""
    return render_template('menu.html')

@app.route('/customer/inquiry', methods=['GET', 'POST'])
def customer_inquiry():
    """CUSTINQ1 - Basic customer inquiry (INQ1)"""
    
    if request.method == 'POST':
        action = request.form.get('action', 'search')
        customer_number = request.form.get('customer_number')
        
        customer = None
        error = None
        
        if action == 'search' and customer_number:
            # Normal inquiry by customer number
            try:
                customer = customer_repo.find_by_number(int(customer_number))
                if not customer:
                    error = 'Customer not found'
            except ValueError:
                error = 'Invalid customer number'
        
        return render_template('customer_inquiry.html',
                             customer=customer,
                             customer_number=customer_number,
                             error=error)
    
    # GET request - display empty form
    return render_template('customer_inquiry.html')

@app.route('/customer/inquiry2', methods=['GET', 'POST'])
def customer_inquiry2():
    """CUSTINQ2 - Customer inquiry with browse (INQ2)"""
    
    if request.method == 'POST':
        action = request.form.get('action', 'search')
        customer_number = request.form.get('customer_number')
        
        customer = None
        error = None
        
        try:
            if action == 'search' and customer_number:
                customer = customer_repo.find_by_number(int(customer_number))
            elif action == 'first':
                customer = customer_repo.get_first()
            elif action == 'last':
                customer = customer_repo.get_last()
            elif action == 'next' and customer_number:
                customer = customer_repo.get_next(int(customer_number))
            elif action == 'prev' and customer_number:
                customer = customer_repo.get_previous(int(customer_number))
            
            if not customer:
                error = 'No customer found'
                
        except ValueError:
            error = 'Invalid customer number'
        
        return render_template('customer_inquiry2.html',
                             customer=customer,
                             error=error)
    
    return render_template('customer_inquiry2.html')

@app.route('/customer/maintenance', methods=['GET', 'POST'])
def customer_maintenance():
    """CUSTMNT1 - Customer maintenance (MNT1)"""
    
    if request.method == 'POST':
        action = request.form.get('action')
        
        # First screen - get customer number and action code
        if action == 'lookup':
            customer_number = request.form.get('customer_number')
            action_code = request.form.get('action_code')
            
            try:
                customer = customer_repo.find_by_number(int(customer_number))
                
                # Store in session for next screen
                session['mnt_customer_number'] = customer_number
                session['mnt_action_code'] = action_code
                
                if action_code == '1':  # Add
                    if customer:
                        return render_template('customer_maintenance.html',
                                             error='Customer already exists')
                    # Show blank form for new customer
                    return render_template('customer_detail.html',
                                         action='add',
                                         customer_number=customer_number)
                
                elif action_code in ['2', '3']:  # Change or Delete
                    if not customer:
                        return render_template('customer_maintenance.html',
                                             error='Customer not found')
                    # Show existing customer data
                    return render_template('customer_detail.html',
                                         action='change' if action_code == '2' else 'delete',
                                         customer=customer)
                else:
                    return render_template('customer_maintenance.html',
                                         error='Invalid action code (1=Add, 2=Change, 3=Delete)')
                    
            except ValueError:
                return render_template('customer_maintenance.html',
                                     error='Invalid customer number')
        
        # Second screen - process the actual update
        elif action in ['add', 'change', 'delete']:
            customer_number = int(session.get('mnt_customer_number'))
            
            if action == 'add':
                customer = Customer(
                    customer_number=customer_number,
                    first_name=request.form.get('first_name'),
                    last_name=request.form.get('last_name'),
                    address=request.form.get('address'),
                    city=request.form.get('city'),
                    state=request.form.get('state'),
                    zip_code=request.form.get('zip_code')
                )
                customer_repo.create(customer)
                message = 'Customer added successfully'
            
            elif action == 'change':
                customer = Customer(
                    customer_number=customer_number,
                    first_name=request.form.get('first_name'),
                    last_name=request.form.get('last_name'),
                    address=request.form.get('address'),
                    city=request.form.get('city'),
                    state=request.form.get('state'),
                    zip_code=request.form.get('zip_code')
                )
                customer_repo.update(customer)
                message = 'Customer updated successfully'
            
            elif action == 'delete':
                customer_repo.delete(customer_number)
                message = 'Customer deleted successfully'
            
            # Clear session
            session.pop('mnt_customer_number', None)
            session.pop('mnt_action_code', None)
            
            return render_template('customer_maintenance.html',
                                 message=message)
    
    return render_template('customer_maintenance.html')

if __name__ == '__main__':
    app.run(debug=True)
```

---

## Next Steps

1. **Extract the XMI file** on MVS 3.8J to get actual COBOL source and copybooks
2. **Analyze the copybooks** to get exact record layouts
3. **Start with Phase 1** - Database setup and sample data
4. **Convert CUSTINQ1** first - it's the simplest
5. **Iterate** through remaining programs in order of complexity

Would you like me to:
- Create the complete Flask application with all templates?
- Build the terminal UI version using textual?
- Generate SQL scripts for data migration?
- Show how to convert a specific program in detail?
- Create unit tests for the conversion?

Let me know which aspect you'd like to explore next!
