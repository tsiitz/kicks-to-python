"""
Database layer for KICKS/COBOL to Python conversion
Replaces VSAM file operations with SQL database operations
"""

import sqlite3
from typing import Optional, List
from contextlib import contextmanager
from decimal import Decimal
from datetime import datetime, date
from models import Customer, Product, Invoice, InvoiceItem


# Register adapters for Decimal type support in SQLite
def adapt_decimal(d):
    """Convert Decimal to float for SQLite storage"""
    return float(d)

def convert_decimal(s):
    """Convert SQLite float back to Decimal"""
    return Decimal(str(s.decode('utf-8')))

# Register the adapters
sqlite3.register_adapter(Decimal, adapt_decimal)
sqlite3.register_converter("decimal", convert_decimal)


class Database:
    """Database connection and initialization"""
    
    def __init__(self, db_path: str = 'mainframe.db'):
        self.db_path = db_path
        self.init_database()
    
    @contextmanager
    def get_connection(self):
        """
        Context manager for database connections
        Equivalent to CICS transaction integrity
        """
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row  # Access columns by name
        try:
            yield conn
            conn.commit()
        except Exception as e:
            conn.rollback()
            raise
        finally:
            conn.close()
    
    def init_database(self):
        """Initialize database schema - replaces VSAM file definitions"""
        with self.get_connection() as conn:
            # Customer Master (CUSTMAS)
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
            
            # Product Master (PRODUCT)
            conn.execute('''
                CREATE TABLE IF NOT EXISTS products (
                    product_code VARCHAR(10) PRIMARY KEY,
                    product_description VARCHAR(40),
                    unit_price DECIMAL(7,2),
                    quantity_on_hand INTEGER,
                    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            ''')
            
            # Invoice Header (INVOICE)
            conn.execute('''
                CREATE TABLE IF NOT EXISTS invoices (
                    invoice_number INTEGER PRIMARY KEY,
                    customer_number INTEGER NOT NULL,
                    invoice_date DATE,
                    invoice_total DECIMAL(9,2),
                    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (customer_number) REFERENCES customers(customer_number)
                )
            ''')
            
            # Invoice Line Items
            conn.execute('''
                CREATE TABLE IF NOT EXISTS invoice_items (
                    invoice_number INTEGER,
                    line_number INTEGER,
                    product_code VARCHAR(10),
                    quantity INTEGER,
                    unit_price DECIMAL(7,2),
                    line_total DECIMAL(9,2),
                    PRIMARY KEY (invoice_number, line_number),
                    FOREIGN KEY (invoice_number) REFERENCES invoices(invoice_number),
                    FOREIGN KEY (product_code) REFERENCES products(product_code)
                )
            ''')
            
            # Create indexes (replaces VSAM alternate indexes)
            conn.execute('''
                CREATE INDEX IF NOT EXISTS idx_invoice_customer 
                ON invoices(customer_number)
            ''')
            conn.execute('''
                CREATE INDEX IF NOT EXISTS idx_invoice_date 
                ON invoices(invoice_date)
            ''')


class CustomerRepository:
    """
    Data access for Customer records
    Replaces VSAM CUSTMAS file operations
    """
    
    def __init__(self, database: Database):
        self.db = database
    
    def find_by_number(self, customer_number: int) -> Optional[Customer]:
        """
        READ FILE('CUSTMAS') RIDFLD(CUSTOMER-NUMBER)
        Equivalent to EXEC CICS READ in COBOL
        """
        with self.db.get_connection() as conn:
            cursor = conn.execute(
                '''SELECT customer_number, first_name, last_name, 
                          address, city, state, zip_code
                   FROM customers 
                   WHERE customer_number = ?''',
                (customer_number,)
            )
            row = cursor.fetchone()
            return self._row_to_customer(row) if row else None
    
    def get_first(self) -> Optional[Customer]:
        """
        STARTBR + READNEXT (first record)
        Equivalent to EXEC CICS STARTBR + READNEXT in COBOL
        """
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
        """
        STARTBR + READPREV (last record)
        Equivalent to EXEC CICS STARTBR + READPREV in COBOL
        """
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
        """
        READNEXT after current position
        Implements forward browse through file
        """
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
        """
        READPREV before current position
        Implements backward browse through file
        """
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
    
    def get_all(self) -> List[Customer]:
        """Get all customers (for reports)"""
        with self.db.get_connection() as conn:
            cursor = conn.execute(
                '''SELECT customer_number, first_name, last_name,
                          address, city, state, zip_code
                   FROM customers 
                   ORDER BY customer_number'''
            )
            return [self._row_to_customer(row) for row in cursor.fetchall()]
    
    def create(self, customer: Customer) -> Customer:
        """
        WRITE FILE('CUSTMAS')
        Equivalent to EXEC CICS WRITE in COBOL
        """
        with self.db.get_connection() as conn:
            conn.execute(
                '''INSERT INTO customers 
                   (customer_number, first_name, last_name, address, 
                    city, state, zip_code)
                   VALUES (?, ?, ?, ?, ?, ?, ?)''',
                (customer.customer_number, customer.first_name.strip(),
                 customer.last_name.strip(), customer.address.strip(),
                 customer.city.strip(), customer.state.strip(),
                 customer.zip_code.strip())
            )
        return customer
    
    def update(self, customer: Customer) -> Customer:
        """
        REWRITE FILE('CUSTMAS')
        Equivalent to EXEC CICS REWRITE in COBOL
        """
        with self.db.get_connection() as conn:
            conn.execute(
                '''UPDATE customers 
                   SET first_name = ?, last_name = ?, address = ?,
                       city = ?, state = ?, zip_code = ?,
                       modified_date = CURRENT_TIMESTAMP
                   WHERE customer_number = ?''',
                (customer.first_name.strip(), customer.last_name.strip(),
                 customer.address.strip(), customer.city.strip(),
                 customer.state.strip(), customer.zip_code.strip(),
                 customer.customer_number)
            )
        return customer
    
    def delete(self, customer_number: int) -> bool:
        """
        DELETE FILE('CUSTMAS')
        Equivalent to EXEC CICS DELETE in COBOL
        """
        with self.db.get_connection() as conn:
            cursor = conn.execute(
                'DELETE FROM customers WHERE customer_number = ?',
                (customer_number,)
            )
            return cursor.rowcount > 0
    
    def exists(self, customer_number: int) -> bool:
        """Check if customer exists (for duplicate check)"""
        with self.db.get_connection() as conn:
            cursor = conn.execute(
                'SELECT COUNT(*) FROM customers WHERE customer_number = ?',
                (customer_number,)
            )
            return cursor.fetchone()[0] > 0
    
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


class InvoiceRepository:
    """
    Data access for Invoice records
    Replaces VSAM INVOICE file operations (with INVPATH alternate index)
    """
    
    def __init__(self, database: Database):
        self.db = database
    
    def find_by_invoice_number(self, invoice_number: int) -> Optional[Invoice]:
        """READ FILE('INVOICE') RIDFLD(INVOICE-NUMBER)"""
        with self.db.get_connection() as conn:
            cursor = conn.execute(
                '''SELECT invoice_number, customer_number, invoice_date, invoice_total
                   FROM invoices 
                   WHERE invoice_number = ?''',
                (invoice_number,)
            )
            row = cursor.fetchone()
            return self._row_to_invoice(row) if row else None
    
    def find_by_customer(self, customer_number: int) -> List[Invoice]:
        """
        READ FILE('INVPATH') RIDFLD(CUSTOMER-NUMBER)
        Uses alternate index on customer_number
        """
        with self.db.get_connection() as conn:
            cursor = conn.execute(
                '''SELECT invoice_number, customer_number, invoice_date, invoice_total
                   FROM invoices 
                   WHERE customer_number = ?
                   ORDER BY invoice_date DESC
                   LIMIT 10''',  # Match CUSTINQ3 limit
                (customer_number,)
            )
            return [self._row_to_invoice(row) for row in cursor.fetchall()]
    
    def get_items(self, invoice_number: int) -> List[InvoiceItem]:
        """Get line items for an invoice"""
        with self.db.get_connection() as conn:
            cursor = conn.execute(
                '''SELECT invoice_number, line_number, product_code,
                          quantity, unit_price, line_total
                   FROM invoice_items
                   WHERE invoice_number = ?
                   ORDER BY line_number''',
                (invoice_number,)
            )
            return [self._row_to_item(row) for row in cursor.fetchall()]
    
    def _row_to_invoice(self, row) -> Invoice:
        """Convert database row to Invoice object"""
        return Invoice(
            invoice_number=row['invoice_number'],
            customer_number=row['customer_number'],
            invoice_date=datetime.strptime(row['invoice_date'], '%Y-%m-%d').date(),
            invoice_total=Decimal(str(row['invoice_total']))
        )
    
    def _row_to_item(self, row) -> InvoiceItem:
        """Convert database row to InvoiceItem object"""
        return InvoiceItem(
            invoice_number=row['invoice_number'],
            line_number=row['line_number'],
            product_code=row['product_code'],
            quantity=row['quantity'],
            unit_price=Decimal(str(row['unit_price'])),
            line_total=Decimal(str(row['line_total']))
        )


class ProductRepository:
    """
    Data access for Product records
    Replaces VSAM PRODUCT file operations
    """
    
    def __init__(self, database: Database):
        self.db = database
    
    def find_by_code(self, product_code: str) -> Optional[Product]:
        """READ FILE('PRODUCT') RIDFLD(PRODUCT-CODE)"""
        with self.db.get_connection() as conn:
            cursor = conn.execute(
                '''SELECT product_code, product_description, unit_price, quantity_on_hand
                   FROM products 
                   WHERE product_code = ?''',
                (product_code.strip().ljust(10),)
            )
            row = cursor.fetchone()
            return self._row_to_product(row) if row else None
    
    def _row_to_product(self, row) -> Product:
        """Convert database row to Product object"""
        return Product(
            product_code=row['product_code'],
            description=row['product_description'],
            unit_price=Decimal(str(row['unit_price'])),
            quantity_on_hand=row['quantity_on_hand']
        )


def initialize_sample_data():
    """
    Initialize database with sample data from Murach book examples
    Equivalent to loading VSAM files with test data
    """
    db = Database()
    customer_repo = CustomerRepository(db)
    product_repo = ProductRepository(db)
    
    # Check if data already exists
    if customer_repo.exists(400001):
        print("Sample data already exists")
        return
    
    print("Creating sample data...")
    
    # Sample customers (from book)
    customers = [
        Customer(400001, 'Keith', 'Jones', '5841 Oak Leaf Drive', 'Campbell', 'CA', '95008'),
        Customer(400002, 'Lisa', 'Smith', '3812 Oak Leaf Drive', 'Campbell', 'CA', '95008'),
        Customer(400003, 'Susan', 'Myers', '4819 Willow Way', 'San Jose', 'CA', '95110'),
        Customer(400004, 'John', 'Davis', '9201 Pine Street', 'Sunnyvale', 'CA', '94086'),
        Customer(400005, 'Anne', 'Wright', '1432 Elm Avenue', 'San Jose', 'CA', '95112'),
        Customer(400006, 'Bob', 'Johnson', '7723 Maple Lane', 'Los Gatos', 'CA', '95030'),
        Customer(400007, 'Mary', 'Williams', '2901 Cedar Court', 'Santa Clara', 'CA', '95051'),
    ]
    
    for customer in customers:
        customer_repo.create(customer)
    
    # Sample products
    with db.get_connection() as conn:
        products_data = [
            ('0000000001', 'Widget Standard', 10.50, 500),
            ('0000000005', 'Gadget Deluxe', 25.99, 250),
            ('0000000010', 'Doohickey Pro', 99.99, 100),
            ('0000000020', 'Thingamajig Basic', 5.00, 1000),
            ('0000000025', 'Whatchamacallit Plus', 15.75, 300),
        ]
        
        for prod in products_data:
            conn.execute('''
                INSERT INTO products (product_code, product_description, unit_price, quantity_on_hand)
                VALUES (?, ?, ?, ?)
            ''', prod)
        
        # Sample invoices
        invoices_data = [
            (100001, 400001, '2024-01-15', 157.48),
            (100002, 400001, '2024-02-20', 51.98),
            (100003, 400002, '2024-01-10', 289.97),
            (100004, 400003, '2024-03-05', 125.49),
        ]
        
        for inv in invoices_data:
            conn.execute('''
                INSERT INTO invoices (invoice_number, customer_number, invoice_date, invoice_total)
                VALUES (?, ?, ?, ?)
            ''', inv)
    
    print("Sample data created successfully!")
    print(f"Created {len(customers)} customers")
    print("Created 5 products")
    print("Created 4 sample invoices")


if __name__ == '__main__':
    # Initialize database and load sample data
    initialize_sample_data()
