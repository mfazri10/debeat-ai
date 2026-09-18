package knowledge

import (
	"net/http"

	"github.com/debateai/api-gateway/pkg/database"
	"github.com/debateai/api-gateway/pkg/grpcclient"
	"github.com/labstack/echo/v4"
)

type Handler struct {
	db          *database.DB
	grpcClients *grpcclient.Clients
}

func NewHandler(db *database.DB, grpcClients *grpcclient.Clients) *Handler {
	return &Handler{
		db:          db,
		grpcClients: grpcClients,
	}
}

func (h *Handler) Search(c echo.Context) error {
	query := c.QueryParam("q")
	return c.JSON(http.StatusOK, map[string]interface{}{
		"query":   query,
		"results": []interface{}{},
	})
}

func (h *Handler) IngestYouTube(c echo.Context) error {
	return c.JSON(http.StatusAccepted, map[string]string{
		"status":  "PROCESSING",
		"message": "YouTube transcript extraction in progress",
	})
}

func (h *Handler) IngestPDF(c echo.Context) error {
	return c.JSON(http.StatusAccepted, map[string]string{
		"status":  "PROCESSING",
		"message": "PDF ingestion pipeline started",
	})
}
