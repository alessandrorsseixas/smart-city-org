package smart.city.org.eletric.control.entities;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.mongodb.core.mapping.Document;
import smart.city.org.eletric.control.enums.BatteryStatus;

@Document(collection = "bateries")
@Data
@AllArgsConstructor
@NoArgsConstructor
public class Battery extends entity{


    @Min(0)
    @NotNull
    public Double capacity;

    @Min(0)
    @NotNull
    public Double currentCharge;

    @Min(0)
    @NotNull
    public Double healthStatus;

    @NotBlank
    public String lastMaintenance;

    @NotBlank
    public String installationDate;

    @NotNull
    public BatteryStatus batteryStatus;
}


