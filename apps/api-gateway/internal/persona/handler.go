package persona

import (
	"net/http"

	"github.com/debateai/api-gateway/pkg/database"
	"github.com/labstack/echo/v4"
)

type Handler struct {
	db *database.DB
}

func NewHandler(db *database.DB) *Handler {
	return &Handler{db: db}
}

func (h *Handler) List(c echo.Context) error {
	defaultPersonas := []map[string]interface{}{
		{
			"id":            "p-01",
			"name":          "Prof. Rocky (Kritis & Filosofis)",
			"description":   "Gaya debat argumentatif, membongkar logika premis, tajam dan lugas.",
			"speakingStyle": "Tajam, filosofis, menggunakan analogi tajam dan verifikasi epistimologis.",
			"isTemplate":    true,
		},
		{
			"id":            "p-02",
			"name":          "Dr. Gita (Diplomatis & Empatik)",
			"description":   "Fokus pada data empiris, dampak sosial, dan solusi konstruktif.",
			"speakingStyle": "Tenang, terstruktur, berbasis data ekonomi dan analogi kebijakan publik.",
			"isTemplate":    true,
		},
	}
	return c.JSON(http.StatusOK, defaultPersonas)
}

func (h *Handler) GetByID(c echo.Context) error {
	id := c.Param("id")
	return c.JSON(http.StatusOK, map[string]string{"id": id, "name": "Persona Detail"})
}

func (h *Handler) Create(c echo.Context) error {
	return c.JSON(http.StatusCreated, map[string]string{"status": "created"})
}

func (h *Handler) Update(c echo.Context) error {
	return c.JSON(http.StatusOK, map[string]string{"status": "updated"})
}

func (h *Handler) Delete(c echo.Context) error {
	return c.JSON(http.StatusOK, map[string]string{"status": "deleted"})
}
