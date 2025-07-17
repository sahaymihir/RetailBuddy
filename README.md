RetailBuddy - Comprehensive Point of Sale (POS) System
RetailBuddy is a modern, robust, and feature-rich Point of Sale (POS) application designed to streamline retail operations. Built with Ruby on Rails and an Oracle database backend, it provides a complete solution for managing sales, inventory, customers, and reporting, all from a sleek and intuitive web interface.

Table of Contents
Project Documentation

Key Features

Screenshots

Tech Stack

Getting Started

Prerequisites

Installation & Setup

Usage

Default Login Credentials

Running Tests

Deployment

Contributing

License

Project Documentation
For a detailed understanding of the project's scope, objectives, and system requirements, please refer to the following documents:

Project Synopsis

Software Requirement Specification (SRS)

Key Features
Intuitive Billing System: A dynamic billing interface for quick and efficient transaction processing.

Product & Category Management: Easily add, update, and organize products with custom categories and tax rates.

Inventory Control: Real-time stock tracking with low-stock alerts and reorder level management.

Customer Relationship Management (CRM): Maintain a database of your customers and track their purchase history.

Comprehensive Reporting: Generate detailed reports on sales, top-selling products, customer activity, and more. Export reports to CSV for further analysis.

User & Role Management: Secure authentication system with distinct roles for Admins and Employees.

Responsive Design: Fully functional across desktops, tablets, and mobile devices.

Screenshots

Login Page

Dashboard

Billing Interface







Inventory Management

Reports

Customer Management







Tech Stack
Backend:

Ruby on Rails 7.1 <img src="https://img.shields.io/badge/Ruby_on_Rails-CC0000?style=for-the-badge&logo=ruby-on-rails&logoColor=white" alt="Ruby on Rails" style="height: 20px;"/>

Ruby <img src="https://www.google.com/search?q=https://img.shields.io/badge/Ruby-CC342D%3Fstyle%3Dfor-the-badge%26logo%3Druby%26logoColor%3Dwhite" alt="Ruby" style="height: 20px;"/>

Database:

Oracle <img src="https://www.google.com/search?q=https://img.shields.io/badge/Oracle-F80000%3Fstyle%3Dfor-the-badge%26logo%3Doracle%26logoColor%3Dwhite" alt="Oracle" style="height: 20px;"/>

Frontend:

HTML5 <img src="https://www.google.com/search?q=https://img.shields.io/badge/HTML5-E34F26%3Fstyle%3Dfor-the-badge%26logo%3Dhtml5%26logoColor%3Dwhite" alt="HTML5" style="height: 20px;"/>

CSS3 <img src="https://www.google.com/search?q=https://img.shields.io/badge/CSS3-1572B6%3Fstyle%3Dfor-the-badge%26logo%3Dcss3%26logoColor%3Dwhite" alt="CSS3" style="height: 20px;"/>

JavaScript (ES6+) <img src="https://www.google.com/search?q=https://img.shields.io/badge/JavaScript-F7DF1E%3Fstyle%3Dfor-the-badge%26logo%3Djavascript%26logoColor%3Dblack" alt="JavaScript" style="height: 20px;"/>

Getting Started
Follow these instructions to get a copy of the project up and running on your local machine for development and testing purposes.

Prerequisites
Ruby: Version 3.2.2 or later.

Bundler: gem install bundler

Node.js: Version 18.x or later.

Yarn: npm install -g yarn

Oracle Database: A running instance of Oracle Database (e.g., Oracle XE).

Oracle Instant Client: Required for the ruby-oci8 and activerecord-oracle_enhanced-adapter gems to connect to the database. Ensure it is installed and configured correctly on your system.

Installation & Setup
Clone the repository:

git clone [https://github.com/sahaymihir/retailbuddy.git](https://github.com/sahaymihir/retailbuddy.git)
cd retailbuddy

Install Ruby dependencies:

bundle install

Install JavaScript dependencies:

yarn install

Configure environment variables:
Create a .env file in the root of the project and add your Oracle database credentials. See .env.example if available, or use the following template:

ORACLE_DB_USERNAME=your_username
ORACLE_DB_PASSWORD=your_password
ORACLE_DB_CONNECTION=//your_host:your_port/your_service_name
ORACLE_TNS_ADMIN=/path/to/your/tnsnames.ora/directory

Note: ORACLE_TNS_ADMIN is required if you are using a TNS name for the connection.

Set up the database:
Run the following commands to create the database, run migrations, and seed it with initial data.

rails db:create
rails db:migrate
rails db:seed

Start the Rails server:

rails server

The application should now be running at http://localhost:3000.

Usage
Once the server is running, you can access the application in your web browser.

Default Login Credentials
The db/seeds.rb file creates default users. You can log in with the following credentials:

Test Admin User:

Email: mihir@admin.retailbuddy.com

Password: Mihir@1

Running Tests
To run the test suite, use the following command:

rails test

For system tests, ensure you have the necessary browser drivers (e.g., chromedriver) installed.

rails test:system

Deployment
This application is configured for deployment using Kamal. A sample config/deploy.yml file is included. You will need to customize this file with your server details, registry credentials, and any other environment-specific configurations before deploying.

Contributing
Contributions are welcome! Please feel free to submit a pull request. For major changes, please open an issue first to discuss what you would like to change.

License
This project is licensed under the MIT License - see the LICENSE.md file for details.