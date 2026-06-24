// ReportController creates high-level summaries of how the business is performing.
class ReportController {
    constructor(reportUseCases) {
        this.reportUseCases = reportUseCases;
    }

    // Generates a comprehensive report (revenue, profit, stock health) for the business.
    async getReport(req, res) {
        try {
            const report = await this.reportUseCases.getBusinessReport.execute(req.ownerId);
            res.json({ success: true, data: report });
        } catch (error) {
            console.error('Error generating report:', error);
            res.status(500).json({ success: false, error: 'Failed to generate business report' });
        }
    }
}

module.exports = ReportController;
