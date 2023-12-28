#!/usr/bin/python3
# Copyright (c) BDist Development Team
# Distributed under the terms of the Modified BSD License.
import os
from logging.config import dictConfig
import psycopg
from flask import Flask, flash, jsonify, redirect, render_template, request, url_for
from psycopg.rows import namedtuple_row

# postgres://{user}:{password}@{hostname}:{port}/{database-name}
DATABASE_URL = "postgres://clinic:clinic@postgres/clinic" #os.environ.get("DATABASE_URL", "postgres://clinic:clinic@postgres/clinic")

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


# @app.route("/accounts", methods=("GET",))
# def account_index():
#     """Show all the accounts, most recent first."""

#     with psycopg.connect(conninfo=DATABASE_URL) as conn:
#         with conn.cursor(row_factory=namedtuple_row) as cur:
#             accounts = cur.execute(
#                 """
#                 SELECT account_number, branch_name, balance
#                 FROM account
#                 ORDER BY account_number DESC;
#                 """,
#                 {},
#             ).fetchall()
#             log.debug(f"Found {cur.rowcount} rows.")

#     return render_template("account/index.html", accounts=accounts)


# @app.route("/accounts/<account_number>/update", methods=("GET",))
# def account_update_view(account_number):
#     """Show the page to update the account balance."""

#     with psycopg.connect(conninfo=DATABASE_URL) as conn:
#         with conn.cursor(row_factory=namedtuple_row) as cur:
#             account = cur.execute(
#                 """
#                 SELECT account_number, branch_name, balance
#                 FROM account
#                 WHERE account_number = %(account_number)s;
#                 """,
#                 {"account_number": account_number},
#             ).fetchone()
#             log.debug(f"Found {cur.rowcount} rows.")

#     return render_template("account/update.html", account=account)


# @app.route("/accounts/<account_number>/update", methods=("POST",))
# def account_update_save(account_number):
#     """Update the account balance."""

#     balance = request.form["balance"]

#     error = None

#     if not balance:
#         error = "Balance is required."
#     if not is_decimal(balance):
#         error = "Balance is required to be decimal."

#     if error is not None:
#         flash(error)
#     else:
#         with psycopg.connect(conninfo=DATABASE_URL) as conn:
#             with conn.cursor(row_factory=namedtuple_row) as cur:
#                 cur.execute(
#                     """
#                     UPDATE account
#                     SET balance = %(balance)s
#                     WHERE account_number = %(account_number)s;
#                     """,
#                     {"account_number": account_number, "balance": balance},
#                 )
#             conn.commit()
#         return redirect(url_for("account_index"))


# @app.route("/accounts/<account_number>/delete", methods=("POST",))
# def account_delete(account_number):
#     """Delete the account."""

#     with psycopg.connect(conninfo=DATABASE_URL) as conn:
#         with conn.cursor(row_factory=namedtuple_row) as cur:
#             cur.execute(
#                 """
#                 DELETE FROM account
#                 WHERE account_number = %(account_number)s;
#                 """,
#                 {"account_number": account_number},
#             )
#         conn.commit()
#     return redirect(url_for("account_index"))

# @app.route("/", methods=["GET", "POST"])
# @app.route("/login", methods=["GET", "POST"])
# def login_route():
#     if request.method == 'POST':
#         entered_vat_id = request.form.get('client_id')
#         print(DATABASE_URL, file=sys.stderr)
#         with psycopg.connect(conninfo=DATABASE_URL) as conn:
#             with conn.cursor(row_factory=namedtuple_row) as cur:
#                 cur.execute(
#                     """
#                     SELECT vat_id
#                     FROM client;
#                     """
#                 )
#                 client_vat_ids = cur.fetchall()
#                 if entered_vat_id in client_vat_ids:
#                     return redirect(url_for('clients'))
#                 else:
#                     return render_template('clinic/index.html', error_message='Invalid VAT ID')
                
#     return render_template('clinic/index.html')

# @app.route("/ping", methods=("GET",))
# def ping():
#     log.debug("ping!")
#     return jsonify({"message": "pong!", "status": "success"})

@app.route("/", methods=("GET",))
@app.route("/clients", methods=("GET",))
def clients_index():
    """Show all the clients."""

    with psycopg.connect(conninfo=DATABASE_URL) as conn:
        with conn.cursor(row_factory=namedtuple_row) as cur:
            clients = cur.execute(
                """
                SELECT vat_id, name, street
                FROM client;
                """,
                {},
            ).fetchall()
            log.debug(f"Found {cur.rowcount} rows.")

    return render_template("clinic/index.html", clients=clients)

@app.route("/clients/<client_id>/appointments", methods=("GET",))
def client_appointment_view(client_id):
    """Show client's appointments and consultations."""

    with psycopg.connect(conninfo=DATABASE_URL) as conn:
        with conn.cursor(row_factory=namedtuple_row) as cur:
            appointments = cur.execute(
                """
                SELECT DISTINCT ap.vat_doctor, ap.date_timestamp, ap.description
                FROM client AS c
                JOIN appointment AS ap ON c.vat_id = ap.vat_client
                JOIN consultation AS co ON ap.VAT_doctor = co.vat_doctor AND ap.date_timestamp = co.date_timestamp
                WHERE c.vat_id = %(client_id)s;
                """,
                {"client_id": client_id},
            ).fetchall()
            log.debug(f"Found {cur.rowcount} rows.")

    return render_template("clinic/appointment.html", appointments=appointments)

if __name__ == "__main__":
    app.run(debug=True)
