package smart.city.org.eletric.control.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Date;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class EnergySourceDTO {

    private String id;
    public String type;
    public String location;
    public Double capacity;
    public Double currentGeneration;
    public String status;
    public String lastMaintenance;
    public String installationDate;
    private Date createdAt;
    private String createdBy;
    private Date updatedAt;
    private String updatedBy;
}
