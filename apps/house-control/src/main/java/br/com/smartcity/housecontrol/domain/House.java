package br.com.smartcity.housecontrol.domain;

import lombok.Data;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import java.util.List;

@Data
@Entity
public class House {
    @Id
    private String id;
    private String name;

    @OneToMany
    private List<Device> devices;
}
