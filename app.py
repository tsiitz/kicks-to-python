"""
Flask web application for KICKS/COBOL to Python conversion
Implements the Doug Lowe/Murach sample application suite

This replaces KICKS transaction processing with web-based forms
"""

from flask import Flask, render_template, request, redirect, url_for, session, flash
from database import Database, CustomerRepository, InvoiceRepository, ProductRepository
from models import Customer, CustomerInquiryInput, CustomerInquiryOutput

app = Flask(__name__)
app.secret_key = 'kicks-replacement-secret-key-change-in-production'

# Initialize database and repositories (singleton pattern)
db = Database()
customer_repo = CustomerRepository(db)
invoice_repo = InvoiceRepository(db)
product_repo = ProductRepository(db)


@app.route('/')
def index():
    """
    Main menu - equivalent to INVMENU program (MENU transaction)
    
    Original COBOL: INVMENU.cbl
    Transaction: MENU
    Map: MENSET1
    """
    return render_template('menu.html')


@app.route('/customer/inquiry', methods=['GET', 'POST'])
@app.route('/customer/inquiry/<int:customer_number>', methods=['GET'])
def customer_inquiry(customer_number=None):
    """
    CUSTINQ1 - Basic customer inquiry (INQ1 transaction)
    
    Original COBOL: CUSTINQ1.cbl
    Transaction: INQ1
    Map: INQSET1/INQMAP1
    
    CICS Logic Flow:
    1. RECEIVE MAP - get customer number from screen
    2. READ FILE('CUSTMAS') - fetch customer record
    3. SEND MAP - display customer data
    4. RETURN
    """
    
    # Handle GET request with customer number in URL (from list view)
    if request.method == 'GET' and customer_number is not None:
        try:
            customer = customer_repo.find_by_number(customer_number)
            if customer:
                output = CustomerInquiryOutput.from_customer(
                    customer,
                    message='Customer record displayed'
                )
                return render_template('customer_inquiry.html',
                                     customer=output)
            else:
                return render_template('customer_inquiry.html',
                                     customer_number=customer_number,
                                     error='Customer not found')
        except Exception as e:
            return render_template('customer_inquiry.html',
                                 error=f'System error: {str(e)}')
    
    # Handle POST request (form submission)
    if request.method == 'POST':
        customer_number_str = request.form.get('customer_number', '').strip()
        
        if not customer_number_str:
            return render_template('customer_inquiry.html',
                                 error='Please enter a customer number')
        
        try:
            # READ FILE('CUSTMAS') RIDFLD(CUSTOMER-NUMBER)
            customer = customer_repo.find_by_number(int(customer_number_str))
            
            if customer:
                # Customer found - display data
                output = CustomerInquiryOutput.from_customer(
                    customer,
                    message='Customer record displayed'
                )
                return render_template('customer_inquiry.html',
                                     customer=output)
            else:
                # NOTFND condition
                return render_template('customer_inquiry.html',
                                     customer_number=customer_number_str,
                                     error='Customer not found')
        
        except ValueError:
            return render_template('customer_inquiry.html',
                                 customer_number=customer_number_str,
                                 error='Invalid customer number format')
        except Exception as e:
            # IOERR condition
            return render_template('customer_inquiry.html',
                                 error=f'System error: {str(e)}')
    
    # GET request without customer number - initial screen display
    # Equivalent to first SEND MAP with ERASE
    return render_template('customer_inquiry.html')


@app.route('/customer/inquiry2', methods=['GET', 'POST'])
def customer_inquiry2():
    """
    CUSTINQ2 - Customer inquiry with browse capability (INQ2 transaction)
    
    Original COBOL: CUSTINQ2.cbl
    Transaction: INQ2
    Map: INQSET2/INQMAP2
    
    Added features:
    - PF5: Display first customer
    - PF6: Display last customer
    - PF7: Previous customer
    - PF8: Next customer
    """
    
    if request.method == 'POST':
        action = request.form.get('action', 'search')
        customer_number = request.form.get('customer_number', '').strip()
        
        customer = None
        error = None
        
        try:
            if action == 'search' and customer_number:
                # Normal inquiry by customer number
                customer = customer_repo.find_by_number(int(customer_number))
                if not customer:
                    error = 'Customer not found'
            
            elif action == 'first':
                # STARTBR + READNEXT (first record)
                customer = customer_repo.get_first()
                if not customer:
                    error = 'No customers on file'
            
            elif action == 'last':
                # STARTBR + READPREV (last record)
                customer = customer_repo.get_last()
                if not customer:
                    error = 'No customers on file'
            
            elif action == 'next':
                # READNEXT after current position
                if customer_number:
                    customer = customer_repo.get_next(int(customer_number))
                    if not customer:
                        error = 'End of file reached'
                else:
                    error = 'Current position unknown'
            
            elif action == 'prev':
                # READPREV before current position
                if customer_number:
                    customer = customer_repo.get_previous(int(customer_number))
                    if not customer:
                        error = 'Beginning of file reached'
                else:
                    error = 'Current position unknown'
            
            if customer:
                output = CustomerInquiryOutput.from_customer(customer)
                return render_template('customer_inquiry2.html',
                                     customer=output)
            else:
                return render_template('customer_inquiry2.html',
                                     error=error or 'No customer found')
        
        except ValueError:
            return render_template('customer_inquiry2.html',
                                 error='Invalid customer number format')
        except Exception as e:
            return render_template('customer_inquiry2.html',
                                 error=f'System error: {str(e)}')
    
    return render_template('customer_inquiry2.html')


@app.route('/customer/inquiry3', methods=['GET', 'POST'])
def customer_inquiry3():
    """
    CUSTINQ3 - Customer inquiry with invoices (INQ3 transaction)
    
    Original COBOL: CUSTINQ3.cbl
    Transaction: INQ3
    Map: INQSET3/INQMAP3
    
    Displays customer data plus up to 10 recent invoices
    Uses INVPATH alternate index to access invoices by customer number
    """
    
    if request.method == 'POST':
        action = request.form.get('action', 'search')
        customer_number = request.form.get('customer_number', '').strip()
        
        customer = None
        invoices = []
        error = None
        
        try:
            if action == 'search' and customer_number:
                customer = customer_repo.find_by_number(int(customer_number))
                if customer:
                    # READ FILE('INVPATH') RIDFLD(CUSTOMER-NUMBER)
                    invoices = invoice_repo.find_by_customer(customer.customer_number)
                else:
                    error = 'Customer not found'
            
            elif action == 'first':
                customer = customer_repo.get_first()
                if customer:
                    invoices = invoice_repo.find_by_customer(customer.customer_number)
            
            elif action == 'last':
                customer = customer_repo.get_last()
                if customer:
                    invoices = invoice_repo.find_by_customer(customer.customer_number)
            
            elif action in ['next', 'prev']:
                if customer_number:
                    if action == 'next':
                        customer = customer_repo.get_next(int(customer_number))
                    else:
                        customer = customer_repo.get_previous(int(customer_number))
                    
                    if customer:
                        invoices = invoice_repo.find_by_customer(customer.customer_number)
                    else:
                        error = 'End of file' if action == 'next' else 'Beginning of file'
            
            if customer:
                output = CustomerInquiryOutput.from_customer(customer)
                return render_template('customer_inquiry3.html',
                                     customer=output,
                                     invoices=invoices)
            else:
                return render_template('customer_inquiry3.html',
                                     error=error or 'No customer found')
        
        except Exception as e:
            return render_template('customer_inquiry3.html',
                                 error=f'System error: {str(e)}')
    
    return render_template('customer_inquiry3.html')


@app.route('/customer/maintenance', methods=['GET', 'POST'])
def customer_maintenance():
    """
    CUSTMNT1 - Customer maintenance (MNT1 transaction)
    
    Original COBOL: CUSTMNT1.cbl
    Transaction: MNT1
    Map: MNTSET1
    
    Two-screen process:
    Screen 1: Enter customer number and action (1=Add, 2=Change, 3=Delete)
    Screen 2: Display/edit customer data and confirm action
    """
    
    if request.method == 'POST':
        action = request.form.get('action')
        
        # First screen - lookup customer and action code
        if action == 'lookup':
            customer_number = request.form.get('customer_number', '').strip()
            action_code = request.form.get('action_code', '').strip()
            
            if not customer_number or not action_code:
                return render_template('customer_maintenance.html',
                                     error='Enter both customer number and action code')
            
            try:
                customer_num = int(customer_number)
                customer = customer_repo.find_by_number(customer_num)
                
                # Store in session for next screen (pseudo-conversational)
                session['mnt_customer_number'] = customer_num
                session['mnt_action_code'] = action_code
                
                if action_code == '1':  # Add
                    if customer:
                        return render_template('customer_maintenance.html',
                                             error='Customer already exists - cannot add')
                    # Show blank form for new customer
                    return render_template('customer_detail.html',
                                         action='add',
                                         customer_number=customer_num)
                
                elif action_code == '2':  # Change
                    if not customer:
                        return render_template('customer_maintenance.html',
                                             error='Customer not found')
                    return render_template('customer_detail.html',
                                         action='change',
                                         customer=customer)
                
                elif action_code == '3':  # Delete
                    if not customer:
                        return render_template('customer_maintenance.html',
                                             error='Customer not found')
                    return render_template('customer_detail.html',
                                         action='delete',
                                         customer=customer)
                else:
                    return render_template('customer_maintenance.html',
                                         error='Invalid action code (1=Add, 2=Change, 3=Delete)')
            
            except ValueError:
                return render_template('customer_maintenance.html',
                                     error='Invalid customer number format')
        
        # Second screen - process the actual update
        elif action in ['add', 'change', 'delete']:
            customer_number = session.get('mnt_customer_number')
            action_code = session.get('mnt_action_code')
            
            if not customer_number:
                return redirect(url_for('customer_maintenance'))
            
            try:
                if action == 'add':
                    # WRITE FILE('CUSTMAS')
                    customer = Customer(
                        customer_number=customer_number,
                        first_name=request.form.get('first_name', ''),
                        last_name=request.form.get('last_name', ''),
                        address=request.form.get('address', ''),
                        city=request.form.get('city', ''),
                        state=request.form.get('state', ''),
                        zip_code=request.form.get('zip_code', '')
                    )
                    customer_repo.create(customer)
                    message = f'Customer {customer_number} added successfully'
                
                elif action == 'change':
                    # REWRITE FILE('CUSTMAS')
                    customer = Customer(
                        customer_number=customer_number,
                        first_name=request.form.get('first_name', ''),
                        last_name=request.form.get('last_name', ''),
                        address=request.form.get('address', ''),
                        city=request.form.get('city', ''),
                        state=request.form.get('state', ''),
                        zip_code=request.form.get('zip_code', '')
                    )
                    customer_repo.update(customer)
                    message = f'Customer {customer_number} changed successfully'
                
                elif action == 'delete':
                    # DELETE FILE('CUSTMAS')
                    customer_repo.delete(customer_number)
                    message = f'Customer {customer_number} deleted successfully'
                
                # Clear session data (transaction complete)
                session.pop('mnt_customer_number', None)
                session.pop('mnt_action_code', None)
                
                return render_template('customer_maintenance.html',
                                     message=message)
            
            except Exception as e:
                return render_template('customer_maintenance.html',
                                     error=f'Error processing request: {str(e)}')
    
    # GET request - initial screen
    return render_template('customer_maintenance.html')


@app.route('/reports/customer_list')
def customer_list():
    """
    Simple customer list report
    Demonstrates file browsing (STARTBR/READNEXT pattern)
    """
    customers = customer_repo.get_all()
    return render_template('customer_list.html', customers=customers)


# Error handlers
@app.errorhandler(404)
def not_found(e):
    """Handle 404 errors"""
    return render_template('error.html', 
                         error='Page not found',
                         message='The requested transaction was not found'), 404


@app.errorhandler(500)
def server_error(e):
    """Handle 500 errors - equivalent to CICS abend"""
    return render_template('error.html',
                         error='System error',
                         message='An unexpected error occurred'), 500


if __name__ == '__main__':
    # Initialize database with sample data if needed
    from database import initialize_sample_data
    initialize_sample_data()
    
    print("\n" + "="*60)
    print("KICKS/COBOL to Python Conversion - Sample Application")
    print("="*60)
    print("\nApplication started successfully!")
    print("\nAvailable transactions:")
    print("  MENU - Main menu                   http://localhost:5000/")
    print("  INQ1 - Customer inquiry            http://localhost:5000/customer/inquiry")
    print("  INQ2 - Customer inquiry + browse   http://localhost:5000/customer/inquiry2")
    print("  INQ3 - Customer inquiry + invoices http://localhost:5000/customer/inquiry3")
    print("  MNT1 - Customer maintenance        http://localhost:5000/customer/maintenance")
    print("\nSample data from MVS 3.8J (LOADMUR1):")
    print("  Customers: 400001-400016 (16 customers)")
    print("  Try: 400001 (KIETH MCDONALD), 400003 (SUSAN HOWARD), 400015 (VIVIAN GEORGE)")
    print("  Products: 0000000001-0000010000 (9 currency denominations)")
    print("  Invoices: 3584-3590 (7 invoices from July 23, 1991)")
    print("\nPress Ctrl+C to stop the server")
    print("="*60 + "\n")
    
    app.run(debug=True, port=5000)
