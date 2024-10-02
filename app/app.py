#!/usr/bin/python3
# Copyright (c) BDist Development Team
# Distributed under the terms of the Modified BSD License.
import os
from logging.config import dictConfig
import psycopg
from flask import Flask, flash, jsonify, redirect, render_template, request, url_for
from psycopg.rows import namedtuple_row
from datetime import datetime
DATABASE_URL = os.environ.get("DATABASE_URL", "postgres://{user}:{password}@{hostname}:{port}/{database-name}")

dictConfig(
    {
        "version": 1,
        "formatters": {
            "default": {
                "format": "[%(asctime)s] %(levelname)s in %(module)s:%(lineno)s - %(funcName)20s(): %(message)s",
            }
        },
        "handlers": {
            "wsgi": {
                "class": "logging.StreamHandler",
                "stream": "ext://flask.logging.wsgi_errors_stream",
                "formatter": "default",
            }
        },
        "root": {"level": "INFO", "handlers": ["wsgi"]},
    }
)

app = Flask(__name__)
app.config.from_prefixed_env()
log = app.logger


def is_decimal(s):
    """Returns True if string is a parseable float number."""
    try:
        float(s)
        return True
    except ValueError:
        return False

def fetch_clients(vat_id=None, name=None, location=None):
    log.debug(f"Vat Id:{vat_id} Name: {name} Location:{location}")
    with psycopg.connect(conninfo=DATABASE_URL) as conn:
        with conn.cursor(row_factory=namedtuple_row) as cur:
            if vat_id and name and location:
                cur.execute(
                    """
                    SELECT vat_id, name, street, city, zip_code
                    FROM client
                    WHERE vat_id = %(vat_id)s AND name ILIKE %(name)s AND (street ILIKE %(location)s OR city ILIKE %(location)s OR zip_code ILIKE %(location)s);
                    """,
                    {"vat_id": vat_id, "name": name, "location": f"%{location}%"},
                )
            elif vat_id and name:
                cur.execute(
                    """
                    SELECT vat_id, name, street, city, zip_code
                    FROM client
                    WHERE vat_id = %(vat_id)s AND name ILIKE %(name)s;
                    """,
                    {"vat_id": vat_id, "name": f"%{name}%"},
                )
            elif name and location:
                cur.execute(
                    """
                    SELECT vat_id, name, street, city, zip_code
                    FROM client
                    WHERE name ILIKE %(name)s AND (street ILIKE %(location)s OR city ILIKE %(location)s OR zip_code ILIKE %(location)s);
                    """,
                    {"name": f"%{name}%", "location": f"%{location}%"},
                )
            elif vat_id and location:
                cur.execute(
                    """
                    SELECT vat_id, name, street, city, zip_code
                    FROM client
                    WHERE vat_id = %(vat_id)s AND (street ILIKE %(location)s OR city ILIKE %(location)s OR zip_code ILIKE %(location)s);
                    """,
                    {"vat_id": vat_id, "location": f"%{location}%"},
                )
            elif vat_id:
                cur.execute(
                    """
                    SELECT vat_id, name, street, city, zip_code
                    FROM client
                    WHERE vat_id = %(vat_id)s;
                    """,
                    {"vat_id": vat_id},
                )
            elif name:
                cur.execute(
                    """
                    SELECT vat_id, name, street, city, zip_code
                    FROM client
                    WHERE name ILIKE %(name)s;
                    """,
                    {"name": f"%{name}%"},
                )
            elif location:
                cur.execute(
                    """
                    SELECT vat_id, name, street, city, zip_code
                    FROM client
                    WHERE street ILIKE %(location)s OR city ILIKE %(location)s OR zip_code ILIKE %(location)s;
                    """,
                    {"location": f"%{location}%"},
                )
            else:
                cur.execute(
                    """
                    SELECT vat_id, name, street, city, zip_code
                    FROM client;
                    """
                )
            clients = cur.fetchall()
            log.debug(f"Found {cur.rowcount} rows.")
            
    return clients

def create_client(vat_id, name, birth_date, street, city=None, zip_code=None, gender=None):
    log.debug(f"Vat Id:{vat_id} Name: {name} BirthDate: {birth_date} Street:{street} City: {city} ZipCode: {zip_code} Gender: {gender} lenght: {len(gender)}")
    with psycopg.connect(conninfo=DATABASE_URL) as conn:
        with conn.cursor(row_factory=namedtuple_row) as cur:
            query = """
                    INSERT INTO client
                    VALUES (%s, %s, %s, %s, %s, %s, %s);
                    """
            cur.execute(query, (vat_id, name, birth_date, street, city, zip_code, gender))
            conn.commit()
    return


def fetch_doctors(timestamp=None):
    log.debug(f"Time:{timestamp}")
    with psycopg.connect(conninfo=DATABASE_URL) as conn:
        with conn.cursor(row_factory=namedtuple_row) as cur:
            if timestamp:
                cur.execute(
                    """
                    SELECT d.VAT_ID AS vat_id, e.name AS name
                    FROM doctor AS d
                    JOIN employee AS e ON e.VAT_ID = d.VAT_ID
                    LEFT JOIN appointment AS ap ON d.VAT_ID = ap.VAT_doctor AND ap.date_timestamp = %(timestamp)s
                    WHERE ap.VAT_doctor IS NULL;
                    """,
                    {"timestamp": timestamp},
                )
            else:
                cur.execute(
                    """
                    SELECT d.VAT_ID AS vat_id, e.name AS name
                    FROM doctor AS d
                    JOIN employee AS e ON e.VAT_ID = d.VAT_ID
                    """,
                    {},
                )
            doctors = cur.fetchall()
    return doctors


def fetch_nurses():
    with psycopg.connect(conninfo=DATABASE_URL) as conn:
        with conn.cursor(row_factory=namedtuple_row) as cur:
            cur.execute(
                """
                SELECT n.vat_id AS vat_id, e.name AS name
                FROM nurse AS n
                JOIN employee AS e ON e.vat_id = n.vat_id
                """,
                {},
            )
            nurses = cur.fetchall()
    return nurses

def fetch_diag():
    with psycopg.connect(conninfo=DATABASE_URL) as conn:
        with conn.cursor(row_factory=namedtuple_row) as cur:
            cur.execute(
                """
                SELECT ID, description
                FROM diagnostic_code
                """,
                {},
            )
            diag = cur.fetchall()
    return diag


def fetch_meds():
    with psycopg.connect(conninfo=DATABASE_URL) as conn:
        with conn.cursor(row_factory=namedtuple_row) as cur:
            cur.execute(
                """
                SELECT name, lab
                FROM medication
                """,
                {},
            )
            meds = cur.fetchall()
    return meds

def fetch_appointments_consultations(client_id):
    with psycopg.connect(conninfo=DATABASE_URL) as conn:
            with conn.cursor(row_factory=namedtuple_row) as cur:
                cur.execute(
                    """
                    SELECT ap.vat_doctor AS vat_doctor, e.name AS doctor_name, ap.date_timestamp AS date_timestamp, ap.description AS description
                    FROM client AS c
                    JOIN appointment AS ap ON c.vat_id = ap.vat_client
                    JOIN employee AS e ON e.vat_id = ap.vat_doctor
                    LEFT JOIN consultation AS co ON ap.vat_doctor = co.vat_doctor AND ap.date_timestamp = co.date_timestamp
                    WHERE ap.vat_client = %(client_id)s
                    ORDER BY ap.date_timestamp;
                    """,
                    {"client_id":client_id},
                )
                appointments = cur.fetchall()
                return appointments

def fetch_consultation_details(client_id, consultation_date, doctor_id):
    log.debug(f"Client ID: {client_id} DateTime: {consultation_date} Doctor ID: {doctor_id}")
    with psycopg.connect(conninfo=DATABASE_URL) as conn:
        with conn.cursor(row_factory=namedtuple_row) as cur:
            cur.execute(
                """
                SELECT * FROM consultation_details
                WHERE vat_client = %(client_id)s AND vat_doctor = %(doctor_id)s AND date_timestamp = %(consultation_date)s ;
                """,
                {"client_id":client_id, "doctor_id":doctor_id, "consultation_date":consultation_date},
            )
            appointment_details = cur.fetchall()
        return appointment_details

def query_lab_for_medication(med_name):
    with psycopg.connect(conninfo=DATABASE_URL) as conn:
        with conn.cursor(row_factory=namedtuple_row) as cur:
            cur.execute(
                """
                SELECT lab
                FROM medication
                WHERE name = %(med_name)s;
                """,
                {"med_name": med_name}),
            lab = cur.fetchone()
    return lab

def create_appointment(doctor_id, timestamp_str, client_id, description):
    log.debug(f"Client Id:{client_id} Timestamp: {timestamp_str} Doctor Id: {doctor_id} Description:{description}")
    try:
        with psycopg.connect(conninfo=DATABASE_URL) as conn:
            with conn.cursor(row_factory=namedtuple_row) as cur:
                query = """
                        INSERT INTO appointment
                        VALUES (%s, %s, %s, %s);
                        """
                cur.execute(query, (doctor_id, timestamp_str, client_id, description))
                conn.commit()
    except Exception as e:
        log.error(f"Error in create_appointment: {e}")

def create_consultation(doctor_id, nurse_id, consultation_date, diag_id, soap_s, soap_o, soap_a, soap_p, prescriptions):
    log.debug(f"Doctor Id:{doctor_id} Nurse Id:{nurse_id} Timestamp: {consultation_date} ID: {diag_id}, SOAP S: {soap_s} SOAP O: {soap_o} SOAP A: {soap_a} SOAP P: {soap_p} Prescriptions: {prescriptions}")
    try:
        with psycopg.connect(conninfo=DATABASE_URL) as conn:
            with conn.cursor(row_factory=namedtuple_row) as cur:
                query = """
                        INSERT INTO consultation
                        VALUES (%s, %s, %s, %s, %s, %s);
                        """
                cur.execute(query, (doctor_id, consultation_date, soap_s, soap_o, soap_a, soap_p))
                conn.commit()
                
                query = """
                        INSERT INTO consultation_assistant
                        VALUES (%s, %s, %s);
                        """
                cur.execute(query, (doctor_id, consultation_date, nurse_id))
                conn.commit()
                
                cur.execute("""
                    INSERT INTO consultation_diagnostic
                    VALUES (%s, %s, %s);
                """, (doctor_id, consultation_date, diag_id))
                conn.commit()
                
                for presc in prescriptions:
                    cur.execute("""
                        INSERT INTO prescription
                        VALUES (%s, %s, %s, %s, %s, %s, %s);
                    """, (doctor_id, consultation_date, diag_id, presc['med_name'], presc['med_lab'], presc['dosage'], presc['description']))
                conn.commit()
                
    except Exception as e:
        log.error(f"Error in create_consultation: {e}")

def fetch_client_cons(client_id):
    try:
        with psycopg.connect(conninfo=DATABASE_URL) as conn:
            with conn.cursor(row_factory=namedtuple_row) as cur:
                cur.execute(
                    """
                    SELECT dd.year_ AS year, SUM(fc.num_diagnostic_codes) AS total_diagnostic_codes, SUM(fc.num_procedures) AS total_procedures
                    FROM facts_consultations fc
                    JOIN dim_date dd ON fc.date = dd.date
                    WHERE fc.VAT = %(client_id)s
                    GROUP BY ROLLUP(dd.year_)
                    ORDER BY year;
                    """,
                    {"client_id":client_id},
                ) 
                client_cons_data = cur.fetchall()
            return client_cons_data
    except Exception as e:
        log.error(f"Error in create_consultation: {e}")

def aggregate_consultations(clients_data):
    aggregated_clients = []
    for client in clients_data:
        update_idx = None
        client_id, name, _, _, _ = client
        client_cons_data = fetch_client_cons(client_id)
        log.debug(client_cons_data)

        for idx, aggregated_client in enumerate(aggregated_clients):
            if aggregated_client['id'] == client_id:
                update_idx = idx
                break
        if update_idx is not None:
            continue
        else:
            # Client doesn't exist, create a new entry
            new_client_entry = {'id': client_id, 'name': name,
                                'consultations': 
                                    [{
                                        'year': int(row.year) if row.year is not None else None,
                                        'total_diagnostic_codes': int(row.total_diagnostic_codes) if row.total_diagnostic_codes is not None else 0,
                                        'total_procedures': int(row.total_procedures) if row.total_procedures is not None else 0
                                    }
                                     for row in client_cons_data]
                                }
            aggregated_clients.append(new_client_entry)

    return aggregated_clients

@app.route("/", methods=("GET", "POST",))
@app.route("/clients", methods=("GET", "POST",))
def clients_index():
    """Show all the clients."""
    if request.method == "POST":
        vat_id = request.form.get("vat_id")
        name = request.form.get("name")
        location = request.form.get("location")
        clients = fetch_clients(vat_id, name, location)
    else:
        clients = fetch_clients()

    return render_template("clinic/index.html", clients=clients)

@app.route("/doctors", methods=("GET", "POST",))
def doctors_index():
    """Show all the doctors."""
    if request.method == "POST":
        date = datetime.strptime(request.form.get("date"), "%Y-%m-%d")
        time = datetime.strptime(request.form.get("time"), "%H:%M").time()
        combined_datetime = datetime.combine(date, time)
        timestamp_str = combined_datetime.strftime('%Y-%m-%d %H:%M:%S')
        doctors = fetch_doctors(timestamp_str)
    else:
        doctors = fetch_doctors()

    return render_template("clinic/doctors.html", doctors=doctors)

@app.route("/dashboard", methods=("GET",))
def dashboard_index():
    """Show the dashboard."""
    client_facts = fetch_clients()
    clients = aggregate_consultations(client_facts)
    return render_template("clinic/dashboard.html", clients=clients)

@app.route("/create_client", methods=("GET","POST",))
def create_client_view():
    """Create clients."""
    if request.method == "POST":
        vat_id = request.form.get("vat_id")
        name = request.form.get("name")
        birth_date = datetime.strptime(request.form.get("birth_date"), "%Y-%m-%d")
        street = request.form.get("street")
        city = request.form.get("city")
        zip_code = request.form.get("zip_code")
        gender = request.form.get("gender")
        create_client(vat_id, name, birth_date, street, city, zip_code, gender)
        return redirect(url_for("clients_index"))
    
    return render_template("clinic/create_client.html")

@app.route("/appointments/<client_id>", methods=("GET",))
def client_appointment_view(client_id):
    """Show client's appointments and consultations."""

    appointments = fetch_appointments_consultations(client_id)
    return render_template("clinic/appointment.html", client_id=client_id, appointments=appointments)

@app.route("/create_appointment/<client_id>", methods=("GET","POST",))
def create_appointment_view(client_id):
    """Show client's appointments and consultations."""
    doctors = []
    if request.method == "POST":
        log.debug("POSTTTT")
        log.debug(request.form.get("date"))
        # Check if all required fields are present
        if request.form.get("date") != None:
            date = datetime.strptime(request.form.get("date"), "%Y-%m-%d")
        if request.form.get("time") != None:
            time = datetime.strptime(request.form.get("time"), "%H:%M").time()
        combined_datetime = datetime.combine(date, time)
        timestamp_str = combined_datetime.strftime('%Y-%m-%d %H:%M:%S')

        doctor_id = request.form.get("doctor_id")
        description = request.form.get("description")

        # Assuming you have some logic to fetch doctors
        doctors = fetch_doctors(timestamp_str)
        if timestamp_str != None and doctor_id != None and description != None:
            create_appointment(doctor_id, timestamp_str, client_id, description)
            return redirect(url_for('client_appointment_view', client_id=client_id))

    return render_template("clinic/create_appointment.html", client_id=client_id, doctors=doctors)

@app.route("/create_consultation/<client_id>/<doctor_id>/<consultation_date>", methods=("GET","POST",))
def create_consultation_view(client_id, doctor_id, consultation_date):
    """Show client's appointments and consultations."""
    log.debug(f"Doctor ID: {doctor_id} Date: {consultation_date}")
    nurses = fetch_nurses()
    medications = fetch_meds()
    diagnostic_codes = fetch_diag()
    if request.method == "POST":
        nurse_id = request.form.get("nurse_id")
        soap_s = request.form.get("soap_s")
        soap_o = request.form.get("soap_o")
        soap_a = request.form.get("soap_a")
        soap_p = request.form.get("soap_p")
        diag_id = request.form.get("diag_code")
        # Diagnostic Codes
        num_presc = int(request.form.get("num_presc"))
        prescriptions = []
        for i in range(num_presc):
            med_name = request.form.getlist("med_name[]")[i]
            med_lab = query_lab_for_medication(med_name)[0]
            dosage = request.form.getlist("dosage[]")[i]
            description = request.form.getlist("description[]")[i]
            log.debug(f"MED NAME: {med_name} MED LAB: {med_lab} DOSAGE: {dosage} DESCRIPTION: {description}")
            prescriptions.append({
                "med_name": med_name,
                "med_lab": med_lab,
                "dosage": dosage,
                "description": description
            })
        create_consultation(doctor_id, nurse_id, consultation_date, diag_id, soap_s, soap_o, soap_a, soap_p, prescriptions)
        return redirect(url_for('consultation_details_view', client_id=client_id, doctor_id=doctor_id, consultation_date=consultation_date))

    else:
        return render_template("clinic/create_consultation.html", client_id=client_id, doctor_id=doctor_id, consultation_date=consultation_date, nurses=nurses, medications=medications, diagnostic_codes=diagnostic_codes)

@app.route("/consultation/<client_id>/<doctor_id>/<consultation_date>", methods=("GET",))
def consultation_details_view(client_id, doctor_id, consultation_date):
    """Show client's consultation details."""
    log.debug(f"Doctor ID: {doctor_id} Date: {consultation_date}")
    appointment_details = fetch_consultation_details(client_id, consultation_date, doctor_id)
    prescription = None
    if appointment_details[0].med_name != None:
        prescription = "\n".join([
            f"{appointment_detail.med_name}, {appointment_detail.lab}, {appointment_detail.dosage}, {appointment_detail.pr_description}"
            for appointment_detail in appointment_details
        ])
    return render_template("clinic/consultation_profile.html", client_id=client_id, appointment_details=appointment_details[0], prescription=prescription)

if __name__ == "__main__":
    app.run(debug=False)

