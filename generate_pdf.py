import matplotlib.pyplot as plt
from fpdf import FPDF
import os

# 1. Generate a Graph
labels = ['Text Reports', 'Code Files', 'PDFs', 'Spreadsheets', 'Images']
sizes = [30, 40, 15, 10, 5]
colors = ['#ff9999','#66b3ff','#99ff99','#ffcc99', '#c2c2f0']
explode = (0.1, 0, 0, 0, 0)

fig1, ax1 = plt.subplots()
ax1.pie(sizes, explode=explode, labels=labels, colors=colors, autopct='%1.1f%%',
        shadow=True, startangle=90)
ax1.axis('equal')  # Equal aspect ratio ensures that pie is drawn as a circle.
plt.title('Types of Data I Can Analyze')

chart_path = 'chart.png'
plt.savefig(chart_path)
plt.close()

# 2. Generate the PDF
pdf = FPDF()
pdf.add_page()
pdf.set_font("Helvetica", size=12)

text_lines = [
    "I can absolutely read text files and other documents, not just code! I can process plain text, Markdown, and even PDFs.",
    "",
    "If you provide me with the path to your text report, I can read it using my tools, analyze its contents, extract the useful insights, and format them into a new document for you.",
    "",
    "Below is an example of a visual I can generate and include in your reports:",
    ""
]

for line in text_lines:
    if line == "":
        pdf.ln(10)
    else:
        pdf.multi_cell(w=190, h=10, text=line)

# Add the image
pdf.image(chart_path, x=30, w=150)

pdf.output("response.pdf")
