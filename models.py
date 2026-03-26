"""
Data models for KICKS/COBOL to Python conversion
Represents COBOL record structures as Python dataclasses
"""

from dataclasses import dataclass, field
from typing import Optional
from datetime import datetime, date
from decimal import Decimal


@dataclass
class Customer:
    """
    Represents CUSTOMER-MASTER-RECORD from COBOL copybook
    
    Original COBOL structure:
    01  CUSTOMER-MASTER-RECORD.
        05  CM-CUSTOMER-NUMBER      PIC 9(6).
        05  CM-FIRST-NAME           PIC X(20).
        05  CM-LAST-NAME            PIC X(30).
        05  CM-ADDRESS              PIC X(30).
        05  CM-CITY                 PIC X(20).
        05  CM-STATE                PIC XX.
        05  CM-ZIP-CODE             PIC X(10).
    """
    customer_number: int              # PIC 9(6)
    first_name: str                   # PIC X(20)
    last_name: str                    # PIC X(30)
    address: str                      # PIC X(30)
    city: str                         # PIC X(20)
    state: str                        # PIC XX
    zip_code: str                     # PIC X(10)
    created_date: Optional[datetime] = None
    modified_date: Optional[datetime] = None
    
    def __post_init__(self):
        """Validate and normalize data (COBOL PICTURE clause enforcement)"""
        # Ensure lengths match COBOL definitions
        self.first_name = self.first_name[:20].ljust(20) if self.first_name else ' ' * 20
        self.last_name = self.last_name[:30].ljust(30) if self.last_name else ' ' * 30
        self.address = self.address[:30].ljust(30) if self.address else ' ' * 30
        self.city = self.city[:20].ljust(20) if self.city else ' ' * 20
        self.state = self.state[:2].ljust(2) if self.state else '  '
        self.zip_code = self.zip_code[:10].ljust(10) if self.zip_code else ' ' * 10
    
    def to_dict(self):
        """Convert to dictionary for JSON serialization"""
        return {
            'customer_number': self.customer_number,
            'first_name': self.first_name.strip(),
            'last_name': self.last_name.strip(),
            'address': self.address.strip(),
            'city': self.city.strip(),
            'state': self.state.strip(),
            'zip_code': self.zip_code.strip(),
            'created_date': self.created_date.isoformat() if self.created_date else None,
            'modified_date': self.modified_date.isoformat() if self.modified_date else None
        }


@dataclass
class Product:
    """
    Represents PRODUCT-MASTER-RECORD from COBOL copybook
    
    Original COBOL structure:
    01  PRODUCT-MASTER-RECORD.
        05  PM-PRODUCT-CODE         PIC X(10).
        05  PM-PRODUCT-DESCRIPTION  PIC X(40).
        05  PM-UNIT-PRICE           PIC S9(5)V99 COMP-3.
        05  PM-QUANTITY-ON-HAND     PIC S9(7) COMP-3.
    """
    product_code: str                 # PIC X(10)
    description: str                  # PIC X(40)
    unit_price: Decimal              # PIC S9(5)V99 COMP-3
    quantity_on_hand: int            # PIC S9(7) COMP-3
    created_date: Optional[datetime] = None
    
    def __post_init__(self):
        """Validate and normalize data"""
        self.product_code = self.product_code[:10].ljust(10)
        self.description = self.description[:40].ljust(40)
        # Ensure unit_price has exactly 2 decimal places (COMP-3 V99)
        if isinstance(self.unit_price, (int, float)):
            self.unit_price = Decimal(str(self.unit_price)).quantize(Decimal('0.01'))


@dataclass
class Invoice:
    """
    Represents INVOICE-MASTER-RECORD from COBOL copybook
    
    Original COBOL structure:
    01  INVOICE-MASTER-RECORD.
        05  IM-INVOICE-NUMBER       PIC 9(6).
        05  IM-CUSTOMER-NUMBER      PIC 9(6).
        05  IM-INVOICE-DATE         PIC 9(8).
        05  IM-INVOICE-TOTAL        PIC S9(7)V99 COMP-3.
    """
    invoice_number: int              # PIC 9(6)
    customer_number: int             # PIC 9(6)
    invoice_date: date              # PIC 9(8) - YYYYMMDD
    invoice_total: Decimal          # PIC S9(7)V99 COMP-3
    
    def __post_init__(self):
        """Ensure proper decimal precision"""
        if isinstance(self.invoice_total, (int, float)):
            self.invoice_total = Decimal(str(self.invoice_total)).quantize(Decimal('0.01'))


@dataclass
class InvoiceItem:
    """
    Represents invoice line items
    
    Original COBOL structure (part of order entry):
    05  ORDER-LINE OCCURS 10 TIMES.
        10  OL-PRODUCT-CODE         PIC X(10).
        10  OL-QUANTITY             PIC 9(5).
        10  OL-UNIT-PRICE           PIC S9(5)V99 COMP-3.
        10  OL-EXTENSION            PIC S9(7)V99 COMP-3.
    """
    invoice_number: int
    line_number: int
    product_code: str
    quantity: int
    unit_price: Decimal
    line_total: Decimal


# Screen data transfer objects (DTOs) - equivalent to COBOL symbolic maps

@dataclass
class CustomerInquiryInput:
    """Input from INQMAP1 (customer inquiry screen)"""
    customer_number: int
    
    @classmethod
    def from_form(cls, form_data):
        """Create from web form data"""
        return cls(customer_number=int(form_data.get('customer_number', 0)))


@dataclass
class CustomerInquiryOutput:
    """Output to INQMAP1 (customer inquiry screen)"""
    customer_number: int = 0
    first_name: str = ""
    last_name: str = ""
    address: str = ""
    city: str = ""
    state: str = ""
    zip_code: str = ""
    message: str = ""
    error: str = ""
    
    @classmethod
    def from_customer(cls, customer: Optional[Customer], message: str = "", error: str = ""):
        """Create from Customer model"""
        if customer:
            return cls(
                customer_number=customer.customer_number,
                first_name=customer.first_name.strip(),
                last_name=customer.last_name.strip(),
                address=customer.address.strip(),
                city=customer.city.strip(),
                state=customer.state.strip(),
                zip_code=customer.zip_code.strip(),
                message=message,
                error=""
            )
        else:
            return cls(error=error)


@dataclass
class CustomerMaintenanceInput:
    """Input for customer maintenance screens"""
    customer_number: int
    action_code: str  # '1'=Add, '2'=Change, '3'=Delete
    first_name: str = ""
    last_name: str = ""
    address: str = ""
    city: str = ""
    state: str = ""
    zip_code: str = ""
