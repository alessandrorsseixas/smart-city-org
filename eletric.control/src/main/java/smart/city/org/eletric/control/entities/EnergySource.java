package smart.city.org.eletric.control.entities;


import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.mongodb.core.mapping.Document;


import java.util.Collection;

@Document(collection ="energysources" )
@Data
@NoArgsConstructor
@AllArgsConstructor
public class EnergySource extends entity{

    @NotBlank
    public String type;
    @Min(0)
    @NotNull
    public Double capacity;
    @NotNull
    @Min(0)
    public Double currentGeneration;
    @NotBlank
    public String status;
    @NotBlank
    public String lastMaintenance;
    @NotBlank
    public String installationDate;

}
